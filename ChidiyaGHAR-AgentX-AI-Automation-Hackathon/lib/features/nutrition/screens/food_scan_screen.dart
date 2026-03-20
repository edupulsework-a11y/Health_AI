import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/api_keys.dart';
import 'symptom_log_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_ai/services/health_service.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  bool _isScanning = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final HealthService _healthService = HealthService();
  String? _selectedMode; // 'cooked' or 'label'
  String? _mealQuantity; // e.g., "200g"

  Future<void> _pickImage(ImageSource source, String mode) async {
    // 1. Show on-screen confirmation (Yes/No)
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera & Storage', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('ChidiyaGHAR needs access to your ${source == ImageSource.camera ? "camera" : "gallery"} to scan your food. Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Yes, Allow'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // 2. Handle permissions
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      if (Platform.isIOS) {
        status = await Permission.photos.request();
      } else {
        // Android 13+ split permissions vs legacy
        final photoStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        
        if (photoStatus.isGranted || storageStatus.isGranted) {
          status = PermissionStatus.granted;
        } else {
          // Try requesting photos first (Android 13+)
          status = await Permission.photos.request();
          if (status.isDenied) {
            // Fallback to legacy storage for older Android
            status = await Permission.storage.request();
          }
        }
      }
    }

    if (!status.isGranted && !status.isLimited) {
      // Small delay to let the dialog close before showing snackbar
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission required to select image.'),
            action: SnackBarAction(label: 'Settings', onPressed: () => openAppSettings()),
          ),
        );
      }
      return;
    }
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Reduce size to stay under Groq's 4MB limit
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedMode = mode;
        });

        if (mode == 'cooked') {
            _showQuantityDialog();
        } else {
            _analyzeImage();
        }
      }
    }

  Future<void> _showQuantityDialog() async {
      final TextEditingController qtyController = TextEditingController();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: const Text("Meal Quantity"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const Text("Enter approx quantity (e.g., 1 bowl, 200g, 1 slice)"),
                    TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(hintText: "e.g., 200g"),
                        autofocus: true,
                    )
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () {
                        Navigator.pop(context); // Close dialog
                        setState(() => _mealQuantity = qtyController.text.isEmpty ? "Standard serving" : qtyController.text);
                        _analyzeImage();
                    },
                    child: const Text("Analyze"),
                )
            ],
        ),
      );
  }

  Future<String?> _uploadToImgBB(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=${ApiKeys.imgBBKey}'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['data']['url'];
      }
    } catch (e) {
      debugPrint('ImgBB Upload Error: $e');
    }
    return null;
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isScanning = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      Map<String, dynamic>? userData;
      if (user != null) {
         userData = await Supabase.instance.client.from('user_data').select().eq('id', user.id).maybeSingle();
      }

      final String userContext = userData != null 
          ? "User identifying as ${userData['gender']}, aged ${userData['age']}. Diet: ${userData['dietary_preference']}."
          : "Standard nutritional context.";

      final String prompt = _selectedMode == 'cooked'
          ? "Analyze this COOKED MEAL image. Context: $userContext Quantity: $_mealQuantity. \n"
            "CRITICAL: Return ONLY a raw JSON object. NO conversational text, NO intro, NO outro. Code blocks are okay but raw text is better.\n"
            "REQUIRED JSON FORMAT: {'items': [{'item_name': 'string', 'total_calories': int, 'total_protein': int, 'total_carbs': int, 'total_fats': int}], 'health_score': int (0-100), 'verdict': 'EAT/AVOID', 'reasoning': 'short explanation', 'advice': 'short tip'}."
          : "Analyze this FOOD LABEL image. Context: $userContext.\n"
            "CRITICAL: Return ONLY a raw JSON object. NO conversational text, NO intro, NO outro.\n"
            "REQUIRED JSON FORMAT: {'items': [{'item_name': 'Label Analysis', 'total_calories': int, 'total_protein': int, 'total_carbs': int, 'total_fats': int}], 'health_score': int, 'verdict': 'EAT/AVOID', 'reasoning': 'short explanation', 'advice': 'short tip'}";

      // 1. Convert image to base64 for Groq Vision
      final List<int> imageBytes = await _selectedImage!.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // 2. Call Groq Vision API
      final groqResponse = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.grokKey}',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'temperature': 0.1,
          'max_completion_tokens': 1024,
        }),
      );

      if (groqResponse.statusCode == 200) {
        final data = jsonDecode(groqResponse.body);
        String content = data['choices'][0]['message']['content'];
        
        // Robust JSON Extraction: Find the search for the first '{' and last '}'
        final int firstBracket = content.indexOf('{');
        final int lastBracket = content.lastIndexOf('}');
        
        if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
          content = content.substring(firstBracket, lastBracket + 1);
        }

        final result = jsonDecode(content);
        
        if (mounted) {
          _showResult(result);
        }
      } else {
        debugPrint('Groq Error Body: ${groqResponse.body}');
        throw 'Vision Scan Failed (Error: ${groqResponse.statusCode})';
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('SocketException') || message.contains('ApiException: 7')) {
          message = "Connection lost. Please check your internet and try again.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showResult(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NutritionResultSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('AI FOOD VISION', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
        ),
        child: Stack(
          children: [
            // Particle-like Glows
            Positioned(top: 100, right: -50, child: _buildGlow(AppColors.primary.withOpacity(0.1))),
            Positioned(bottom: 100, left: -50, child: _buildGlow(AppColors.secondary.withOpacity(0.05))),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeroIcon(),
                    const SizedBox(height: 40),
                    Text(
                      "Futuristic Tracking",
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Scan meals using Groq Vision for real-time\nnutritional decomposition and health scores.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 60),
                    
                    _buildGlassCard(
                      "SCAN COOKED MEAL",
                      "Full nutritional breakdown & portions",
                      Icons.restaurant_rounded,
                      () => _showSourceSelection('cooked'),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassCard(
                      "DECODE FOOD LABEL",
                      "Check ingredients & hidden additives",
                      Icons.qr_code_scanner_rounded,
                      () => _showSourceSelection('label'),
                    ),
                  ],
                ),
              ),
            ),
            if (_isScanning) _buildFuturisticLoading(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)
        ],
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)
        ],
      ),
      child: const Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.white),
    );
  }

  Widget _buildGlassCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticLoading() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 5),
            const SizedBox(height: 32),
            Text(
              "GROQ VISION SCANNING...",
              style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            const Text("Decomposing molecular nutrients", style: TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  void _showSourceSelection(String mode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Source Input", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption("Camera", Icons.camera_rounded, () { Navigator.pop(context); _pickImage(ImageSource.camera, mode); }),
                _buildSourceOption("Gallery", Icons.photo_library_rounded, () { Navigator.pop(context); _pickImage(ImageSource.gallery, mode); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70)),
        ],
      ),
    );
  }
}

class NutritionResultSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const NutritionResultSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List items = data['items'] ?? [];
    final int healthScore = data['health_score'] ?? 0;
    final String verdict = data['verdict'] ?? "UNKNOWN";
    final String reasoning = data['reasoning'] ?? "";
    final String advice = data['advice'] ?? "";

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Health Score Circular Gauge (HTML Reference style)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: healthScore / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(healthScore)),
                        ),
                      ),
                      Column(
                        children: [
                          Text("$healthScore%", style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("HEALTH SCORE", style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Verdict Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _getScoreColor(healthScore).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(verdict == 'EAT' ? Icons.check_circle_outline : Icons.error_outline, color: _getScoreColor(healthScore)),
                          const SizedBox(width: 12),
                          Text("VERDICT: $verdict", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: _getScoreColor(healthScore))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(reasoning, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Text("FOOD DECOMPOSITION", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // List of items with their own small gauges (Reference based)
                ...items.map((item) => _buildItemCard(item)),

                const SizedBox(height: 32),
                
                // Advice Section
                _buildAdviceCard(advice),
                
                const SizedBox(height: 100), // Account for button
              ],
            ),
          ),
          
          // Log Button fixed at bottom
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => SymptomLogScreen(foodData: data, imageUrl: '')));
              },
              icon: const Icon(Icons.add_task_rounded),
              label: Text("LOG MEAL & TRACK", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final int cal = item['total_calories'] ?? 0;
    // Assuming 500kcal is the max for a single item "full" gauge
    final double progress = (cal / 500).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Small Circular Gauge for Calories
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                ),
              ),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['item_name'] ?? "Unknown", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("${item['total_calories']} kcal | P: ${item['total_protein']}g | C: ${item['total_carbs']}g", style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(String advice) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), Colors.transparent]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text("AI PRECISION ADVICE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice, style: GoogleFonts.outfit(color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score > 70) return Colors.tealAccent;
    if (score > 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

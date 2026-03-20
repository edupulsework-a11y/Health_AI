import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/dual_ai_service.dart';

class FoodSafetyScreen extends StatefulWidget {
  const FoodSafetyScreen({super.key});

  @override
  State<FoodSafetyScreen> createState() => _FoodSafetyScreenState();
}

class _FoodSafetyScreenState extends State<FoodSafetyScreen> {
  // ── IoT live data from ESP8266 via Firebase RTDB ──
  int _gasPpm = 0;
  double _temperature = 0;
  double _humidity = 0;
  bool _loadingSensor = true;

  // ── Image input ──────────────────────────────────
  File? _imageFile;
  String? _imageDescription; // from Gemini Vision

  // ── Food item name ───────────────────────────────
  final _foodNameCtrl = TextEditingController();

  // ── Result ───────────────────────────────────────
  FoodSafetyResult? _result;
  bool _analyzing = false;

  final _ai = DualAiService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _subscribeSensorData();
  }

  /// Live subscribe to ESP8266 Firebase RTDB data
  void _subscribeSensorData() {
    final ref = FirebaseDatabase.instance.ref('sensors');
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        setState(() => _loadingSensor = false);
        return;
      }
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        _gasPpm = (map['gas'] ?? map['gas_ppm'] ?? 0) as int;
        _temperature = (map['temperature'] ?? 0.0).toDouble();
        _humidity = (map['humidity'] ?? 0.0).toDouble();
        _loadingSensor = false;
      });
    }, onError: (_) => setState(() => _loadingSensor = false));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() { _imageFile = File(picked.path); _imageDescription = null; _result = null; });
      await _describeImageWithGemini(File(picked.path));
    }
  }

  Future<void> _describeImageWithGemini(File file) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: AppConstants.geminiApiKey);
      final bytes = await file.readAsBytes();
      final response = await model.generateContent([
        Content.multi([
          TextPart("Briefly describe this food item in 1-2 sentences. Include color, texture, and any visible signs of spoilage or freshness."),
          DataPart('image/jpeg', bytes),
        ]),
      ]);
      setState(() => _imageDescription = response.text?.trim() ?? "Food item detected.");
    } catch (_) {
      setState(() => _imageDescription = null);
    }
  }

  Future<void> _analyze() async {
    final name = _foodNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the food item name')));
      return;
    }

    setState(() { _analyzing = true; _result = null; });
    try {
      final result = await _ai.assessFoodSafety(
        foodName: name,
        gasPpm: _gasPpm,
        temperature: _temperature,
        humidity: _humidity,
        imageDescription: _imageDescription,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Safety Checker'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.sensors_rounded, color: AppColors.primaryTeal, size: 14),
              SizedBox(width: 4),
              Text('IoT + AI', style: TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ESP8266 Live Data ─────────────────
            _buildSensorCard(),
            const SizedBox(height: 20),

            // ── Food Name ─────────────────────────
            TextField(
              controller: _foodNameCtrl,
              decoration: InputDecoration(
                labelText: 'Food Item Name (e.g. Mango)',
                prefixIcon: const Icon(Icons.fastfood_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Image picker ─────────────────────
            const Text('Add Food Image (optional but recommended)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _ImagePickBtn(
                  icon: Icons.camera_alt_rounded, label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImagePickBtn(
                  icon: Icons.photo_library_rounded, label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ]),

            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              if (_imageDescription != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.info, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_imageDescription!, style: const TextStyle(fontSize: 12))),
                  ]),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // ── Analyze button ───────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _analyzing ? null : _analyze,
                icon: _analyzing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.science_rounded),
                label: Text(_analyzing ? 'Analyzing...' : 'Analyze Food Safety'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // ── Result card ───────────────────────
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard() {
    Color gasColor = _gasPpm < 100 ? AppColors.success : (_gasPpm <= 200 ? AppColors.warning : AppColors.error);
    String gasLabel = _gasPpm < 100 ? 'Fresh' : (_gasPpm <= 200 ? 'Borderline' : 'Unsafe');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0D1F3C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.sensors_rounded, color: AppColors.primaryTeal, size: 18),
            const SizedBox(width: 8),
            const Text('ESP8266 Live Sensor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_loadingSensor)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal))
            else
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _SensorChip('🌡️ Temp', '${_temperature.toStringAsFixed(1)}°C', Colors.orange),
            const SizedBox(width: 10),
            _SensorChip('💧 Humidity', '${_humidity.toStringAsFixed(1)}%', Colors.blue),
            const SizedBox(width: 10),
            _SensorChip('💨 Gas', '$_gasPpm ppm', gasColor),
          ]),
          const SizedBox(height: 12),
          // Gas bar
          Row(children: [
            Text('Air Quality: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            Text(gasLabel, style: TextStyle(color: gasColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_gasPpm / 300).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(gasColor),
            ),
          ),
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('0 ppm\n🟢 Fresh', style: TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
            Text('100 ppm\n🟡 Eat soon', style: TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
            Text('200+ ppm\n🔴 Discard', style: TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
          ]),
        ],
      ),
    );
  }

  Widget _buildResultCard(FoodSafetyResult result) {
    final Color color = result.isSafe ? AppColors.success : (result.eatSoon ? AppColors.warning : AppColors.error);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(result.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Safety Verdict', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(result.verdict, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
              child: Text('${result.gasPpm} ppm', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ]),
          const Divider(height: 24),
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryTeal, size: 16),
            const SizedBox(width: 6),
            const Text('AI Explanation', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(result.explanation, style: const TextStyle(height: 1.6, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ImagePickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImagePickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryTeal.withAlpha(60)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, color: AppColors.primaryTeal),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

class _SensorChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SensorChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
      );
}

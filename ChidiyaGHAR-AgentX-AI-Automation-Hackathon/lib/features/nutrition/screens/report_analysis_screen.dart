import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/api_keys.dart';
import '../../../services/supabase_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/blockchain_service.dart';

class ReportAnalysisScreen extends StatefulWidget {
  const ReportAnalysisScreen({super.key});

  @override
  State<ReportAnalysisScreen> createState() => _ReportAnalysisScreenState();
}

class _ReportAnalysisScreenState extends State<ReportAnalysisScreen> {
  File? _selectedFile;
  bool _isAnalyzing = false;
  String? _analysisResult;
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _pickFile() async {
    // 1. Show on-screen confirmation (Yes/No)
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Permission', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('We need access to your files to upload and analyze your medical reports. Do you want to proceed?'),
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

    // 2. Handle permissions based on platform/version
    PermissionStatus status;
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

    if (!status.isGranted && !status.isLimited) {
      // Small delay to let the dialog close
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission required to select files.'),
            action: SnackBarAction(label: 'Settings', onPressed: () => openAppSettings()),
          ),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _analysisResult = null;
      });
    }
  }

  Future<void> _analyzeReport() async {
    if (_selectedFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // 1. Upload to Supabase (Optional for hackathon, but good for storage)
      // final url = await _supabaseService.uploadPdf(_selectedFile!);

      // 2. Fetch User Context
      final authUser = Supabase.instance.client.auth.currentUser;
      final userResponse = await Supabase.instance.client.from('user_data').select().eq('id', authUser?.id ?? '').single();
      final contextStr = "Patient: ${userResponse['age']} year old ${userResponse['gender']}, Category: ${userResponse['category']}.";

      // 3. AI Analysis with Gemini (including file data)
      final String base64Image = base64Encode(await _selectedFile!.readAsBytes());
      
      final response = await http.post(
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
                {
                  'type': 'text',
                  'text': 'You are a highly skilled medical report analyzer. $contextStr \n'
                          'Analyze this medical report and provide a detailed summary. \n'
                          '1. Summarize the key findings in simple, easy-to-understand points.\n'
                          '2. Explain what these findings mean for this specific patient based on their context (age, gender, category).\n'
                          '3. Suggest clear next steps or questions to ask a doctor.\n'
                          'Keep the tone professional yet empathetic.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysis = data['choices'][0]['message']['content'];
        
        // 4. Hash and Anchor Analysis to Blockchain
        final recordHash = BlockchainService.generateRecordHash({
          'user_id': authUser?.id,
          'analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        final txHash = await BlockchainService.anchorToBlockchain(recordHash);

        if (mounted) {
          setState(() {
            _analysisResult = analysis;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report Secured on Blockchain! Tx: ${txHash.substring(0, 10)}...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _analysisResult = "Analysis failed. Please try again.");
      }
    } catch (e) {
      setState(() => _analysisResult = "Error: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Report Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile == null ? 'Upload Medical Report' : 'File Selected',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFile == null 
                      ? 'Upload PDF or Images of your Blood report, MRI, etc.' 
                      : _selectedFile!.path.split('/').last,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickFile,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Select File'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedFile != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeReport,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                  child: _isAnalyzing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Start AI Analysis'),
                ),
              ),
            if (_analysisResult != null) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('AI Analysis Result', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Colors.green, size: 12),
                              const SizedBox(width: 4),
                              Text('On-Chain', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_analysisResult!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

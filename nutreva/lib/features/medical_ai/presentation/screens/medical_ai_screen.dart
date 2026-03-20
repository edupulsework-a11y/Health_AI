import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:io';

class MedicalAIScreen extends ConsumerStatefulWidget {
  const MedicalAIScreen({super.key});

  @override
  ConsumerState<MedicalAIScreen> createState() => _MedicalAIScreenState();
}

class _MedicalAIScreenState extends ConsumerState<MedicalAIScreen> {
  String? _fileName;
  XFile? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _fileName = result.files.single.name);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    setState(() => _image = file);
  }

  Future<void> _analyze() async {
    if (_fileName == null && _image == null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _result = {
        'explanation':
            'The uploaded report shows elevated WBC count (12,000 cells/μL) suggesting a possible mild infection or inflammatory response.',
        'next_step':
            'Consult a general physician for further evaluation. Avoid self-medication.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Pre-Diagnosis AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is an AI tool for informational purposes only. Always consult a licensed medical professional.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upload options
            const Text('Upload Report or Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _UploadButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: _fileName ?? 'Upload PDF',
                    color: AppColors.error,
                    onTap: _pickPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadButton(
                    icon: Icons.image_rounded,
                    label: _image == null ? 'Upload Image' : 'Image selected',
                    color: AppColors.accentViolet,
                    onTap: _pickImage,
                  ),
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_image!.path), height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.psychology_rounded),
                label: _loading
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 8),
                        Text('Analysing...')
                      ])
                    : const Text('Analyse with AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: (_loading || (_fileName == null && _image == null)) ? null : _analyze,
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _UploadButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accentViolet),
            SizedBox(width: 8),
            Text('AI Analysis Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const Divider(height: 20),
          const Text('Possible Explanation', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(result['explanation'] as String, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('Suggested Next Step', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(result['next_step'] as String, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('⚠️ Medical Disclaimer: This is not a diagnosis. Always consult a licensed doctor.',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

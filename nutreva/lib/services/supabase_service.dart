import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Upload PDF to Supabase Storage
  Future<String?> uploadPdf(File file) async {
    try {
      final fileName = p.basename(file.path);
      final path = 'reports/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Ensure you have a bucket named 'health_records' created in Supabase
      await _supabase.storage.from('health_records').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get Public URL
      final String publicUrl =
          _supabase.storage.from('health_records').getPublicUrl(path);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading PDF: $e');
      return null;
    }
  }

  // Save Record to Database (Table: report_analysis)
  Future<void> saveAnalysisRecord({
    required String pdfUrl,
    required String analysisResult,
    required String userId,
  }) async {
    try {
      await _supabase.from('report_analysis').insert({
        'user_id': userId,
        'pdf_url': pdfUrl,
        'analysis_result': analysisResult,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving record: $e');
    }
  }
}

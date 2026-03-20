// ============================================================================
// comment_analyzer.dart
// ML Service: Remote AI Review Detection (API-Only)
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Represents the result of an ML analysis check.
class AnalysisResult {
  final bool isHuman;
  final double confidence;
  final String label; // "Human" or "AI"

  AnalysisResult({
    required this.isHuman,
    required this.confidence,
    required this.label,
  });
}

class CommentAnalyzer {
  static const String _remoteApiUrl = 'https://comment-render.onrender.com/predict';

  /// Initialization is now a no-op as we rely 100% on the remote API.
  Future<void> initialize() async {}

  /// Performs analysis via the Render API and returns an [AnalysisResult].
  Future<AnalysisResult> analyzeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_remoteApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String prediction = data['prediction'] ?? 'Human';
        final double confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        
        return AnalysisResult(
          isHuman: prediction != 'AI',
          confidence: confidence,
          label: prediction,
        );
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (_) {
      // In case of any error (network/timeout), we default to Human 
      // with a low confidence or fixed label to avoid blocking legitimate users.
      // Alternatively, we could return a specific error state.
      return AnalysisResult(
        isHuman: true,
        confidence: 0.0,
        label: 'Human (unverified)',
      );
    }
  }

  /// No-op cleanup.
  void dispose() {}
}

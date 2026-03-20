import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

class DualAiService {
  // Gemini Setup
  late final GenerativeModel _geminiModel;

  DualAiService() {}

  /// Queries Groq for holistic Ayurvedic advice using parallel personas
  Future<String> getAyurvedicAdvice(String query) async {
    final String systemPrompt = 
        "You are an expert Ayurvedic Vaidya and Modern Health Consultant. "
        "Provide a concise, holistic answer combining ancient wisdom (Doshas, Herbs) and modern science. "
        "Focus on senior citizens. Keep it respectful, clear, and safe.";

    try {
      // Create futures for parallel personified execution on Groq
      final ayurvedicFuture = _queryGroq(
        "You are an ancient Ayurvedic Vaidya (Doctor). Focus on herbs, doshas, and natural lifestyle.",
        query
      );
      final modernFuture = _queryGroq(
        "You are a modern nutritionist and MD. Focus on clinical evidence, calories, and bio-markers.",
        query
      );

      final results = await Future.wait([ayurvedicFuture, modernFuture]);
      
      return "🌿 **Ayurvedic Wisdom (Vaidya)**:\n${results[0]}\n\n"
             "🔬 **Modern Insight (Science)**:\n${results[1]}\n\n"
             "✨ **Holistic Verdict**: Both perspectives suggest focusing on balance. Please consult a doctor for severe symptoms.";

    } catch (e) {
      return "I apologize, but I'm having trouble connecting to the wisdom archives. Error: $e";
    }
  }

  Future<String> _queryGroq(String persona, String query) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.grokKey}',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': persona},
            {'role': 'user', 'content': query}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return "Insight unavailable (Error: ${response.statusCode})";
      }
    } catch (e) {
      return "Thinking failed. (Error: $e)";
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_sensor_service.dart';

// ── Providers ─────────────────────────────────────────
final aiServiceProvider = Provider<AiFoodService>((ref) => AiFoodService());

// ── Result Models ─────────────────────────────────────
class FoodSafetyResult {
  final String verdict;       // 'Safe', 'Moderate', 'Unsafe'
  final String explanation;
  final List<String> tips;
  final double confidenceScore;

  const FoodSafetyResult({
    required this.verdict,
    required this.explanation,
    required this.tips,
    required this.confidenceScore,
  });
}

class HealthPlan {
  final List<String> morningRoutine;
  final List<String> mealPlan;
  final List<String> hydration;
  final List<String> exercise;
  final List<String> avoidFoods;
  final String note;

  const HealthPlan({
    required this.morningRoutine,
    required this.mealPlan,
    required this.hydration,
    required this.exercise,
    required this.avoidFoods,
    required this.note,
  });
}

// ── AI Service ────────────────────────────────────────
class AiFoodService {
  // Get your free key: https://aistudio.google.com/app/apikey
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';

  late final GenerativeModel _visionModel;
  late final GenerativeModel _textModel;

  AiFoodService() {
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
    );
    _textModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
    );
  }

  /// Analyse food safety using:
  /// - [imageFile] — photo taken by user
  /// - [foodName] — what user typed
  /// - [sensor]   — live ESP8266 readings
  Future<FoodSafetyResult> analyseFoodSafety({
    required File imageFile,
    required String foodName,
    required SensorData sensor,
  }) async {
    final imageBytes = await imageFile.readAsBytes();

    final prompt = '''
You are a food safety expert AI for the Nutreva Health App.

Analyse this food and determine if it is SAFE to eat:

Food Name: $foodName

IoT Sensor Readings (from ESP8266):
- Temperature: ${sensor.temperature.toStringAsFixed(1)}°C
- Humidity: ${sensor.humidity.toStringAsFixed(1)}%
- Gas Level (MQ sensor): ${sensor.gasPpm} ppm

Sensor thresholds:
- Gas > 400 ppm = spoiled/fermented/contaminated
- Humidity > 80% = mold risk
- Temp > 40°C = unsafe storage

Based on the image + sensor readings + food name, respond ONLY in this exact JSON format:
{
  "verdict": "Safe" | "Moderate" | "Unsafe",
  "confidence": 0.0-1.0,
  "explanation": "short explanation in 2 sentences",
  "tips": ["tip 1", "tip 2", "tip 3"]
}
''';

    final response = await _visionModel.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);

    return _parseFoodSafetyResponse(response.text ?? '');
  }

  /// Generate personalised health plan based on user profile + wearable data
  Future<HealthPlan> generateHealthPlan({
    required String userRole,      // 'pregnant', 'fitness', 'regular', etc.
    required int steps,
    required double heartRate,
    required double sleepHours,
    required double calories,
    String? medicalNote,
  }) async {
    final prompt = '''
You are a certified nutritionist AI for the Nutreva Health App.

Generate a PERSONALISED daily health plan for this user:

User Profile:
- Role: $userRole
- Today's Steps: $steps
- Average Heart Rate: ${heartRate.toStringAsFixed(0)} bpm
- Sleep Last Night: ${sleepHours.toStringAsFixed(1)} hours
- Calories Today: ${calories.toStringAsFixed(0)} kcal
${medicalNote != null ? '- Medical Note: $medicalNote' : ''}

Respond ONLY in this exact JSON format:
{
  "morning_routine": ["activity 1", "activity 2", "activity 3"],
  "meal_plan": ["breakfast idea", "lunch idea", "dinner idea", "snack idea"],
  "hydration": ["tip 1", "tip 2"],
  "exercise": ["recommendation 1", "recommendation 2"],
  "avoid_foods": ["food 1", "food 2", "food 3"],
  "note": "one personalised motivational note for the user"
}
''';

    final response = await _textModel.generateContent([Content.text(prompt)]);
    return _parseHealthPlanResponse(response.text ?? '');
  }

  // ── Parsers ───────────────────────────────────────────
  FoodSafetyResult _parseFoodSafetyResponse(String raw) {
    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FoodSafetyResult(
        verdict: map['verdict'] as String? ?? 'Unknown',
        explanation: map['explanation'] as String? ?? '',
        tips: List<String>.from(map['tips'] as List? ?? []),
        confidenceScore: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      );
    } catch (_) {
      return const FoodSafetyResult(
        verdict: 'Unknown',
        explanation: 'Could not analyse. Please try again.',
        tips: ['Ensure good lighting', 'Enter the food name clearly'],
        confidenceScore: 0,
      );
    }
  }

  HealthPlan _parseHealthPlanResponse(String raw) {
    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return HealthPlan(
        morningRoutine: List<String>.from(map['morning_routine'] as List? ?? []),
        mealPlan: List<String>.from(map['meal_plan'] as List? ?? []),
        hydration: List<String>.from(map['hydration'] as List? ?? []),
        exercise: List<String>.from(map['exercise'] as List? ?? []),
        avoidFoods: List<String>.from(map['avoid_foods'] as List? ?? []),
        note: map['note'] as String? ?? '',
      );
    } catch (_) {
      return const HealthPlan(
        morningRoutine: ['Start with 10 min light stretching'],
        mealPlan: ['Balanced breakfast', 'Light lunch', 'Nutritious dinner'],
        hydration: ['Drink 2L of water daily'],
        exercise: ['30 min walk recommended'],
        avoidFoods: ['Processed foods', 'Excess sugar'],
        note: 'Stay consistent with your health goals!',
      );
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1) return '{}';
    return text.substring(start, end + 1);
  }
}

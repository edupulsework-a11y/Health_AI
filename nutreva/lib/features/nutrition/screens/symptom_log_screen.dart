import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../services/health_service.dart';
import 'food_log_success_screen.dart';

class SymptomLogScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final String? imageUrl;

  const SymptomLogScreen({super.key, required this.foodData, this.imageUrl});

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  final List<String> _symptoms = [
    'Bloating', 'Brain Fog', 'Burning', 'Fatigue', 
    'Feel Sick', 'Nausea', 'Skin Itching', 'Throwing up'
  ];
  final Set<String> _selectedSymptoms = {};
  int _severity = 0;
  bool _isSaving = false;

  Future<void> _logMeal() async {
    setState(() => _isSaving = true);
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final items = widget.foodData['items'] as List<dynamic>? ?? [];
    double totalCals = 0, totalProtein = 0, totalCarbs = 0, totalFats = 0;
    String foodName = "Logged Meal";

    if (items.isNotEmpty) {
      for (var item in items) {
        totalCals += (item['total_calories'] ?? 0);
        totalProtein += (item['total_protein'] ?? 0);
        totalCarbs += (item['total_carbs'] ?? 0);
        totalFats += (item['total_fats'] ?? 0);
      }
      foodName = items.first['item_name'] ?? "Meal";
      if (items.length > 1) foodName += " + ${items.length - 1} others";
    }

    try {
      await Supabase.instance.client.from('food_logs').insert({
        'user_id': user.id,
        'food_name': foodName,
        'calories': totalCals,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fats': totalFats,
        'image_url': widget.imageUrl,
        'symptoms': _selectedSymptoms.toList(),
        'symptom_severity': _severity,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update HealthService locally for immediate UI update
      HealthService().addFood(totalCals, totalProtein, totalCarbs, totalFats, 0);
      final streak = await HealthService().getDailyStreak();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FoodLogSuccessScreen(
              logData: {
                'food_name': foodName,
                'calories': totalCals,
                'symptoms': _selectedSymptoms.toList(),
                'symptom_severity': _severity,
              },
              streakDays: streak,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging meal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal Symptoms')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Did this meal cause any symptoms?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select symptoms and rate their severity (0 = none, 5 = severe)',
              style: TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  backgroundColor: AppColors.background,
                  selectedColor: Colors.red.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.red : AppColors.textBody,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.red : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            if (_selectedSymptoms.isNotEmpty) ...[
              const Text('Rate Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isSelected = _severity == index;
                  return GestureDetector(
                    onTap: () => setState(() => _severity = index),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        index.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 4, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 = NONE', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text('5 = SEVERE', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _logMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Log Meal', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

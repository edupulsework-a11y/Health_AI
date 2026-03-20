import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class MealLogScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const MealLogScreen({super.key, this.initialData});

  @override
  ConsumerState<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends ConsumerState<MealLogScreen> {
  double _bloating = 0;
  double _fatigue = 0;
  double _acidity = 0;
  double _energy = 5;
  bool _saved = false;

  void _save() {
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _saved
            ? const Center(
                child: Column(
                children: [
                  SizedBox(height: 60),
                  Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
                  SizedBox(height: 16),
                  Text('Meal Logged!',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success)),
                  SizedBox(height: 8),
                  Text('Great job tracking your nutrition!', style: TextStyle(color: Colors.grey)),
                ],
              ))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal summary card
                  if (widget.initialData != null)
                    _MealSummaryCard(data: widget.initialData!),
                  const SizedBox(height: 24),

                  // Symptom sliders
                  const Text('How did this meal make you feel?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _SymptomSlider(label: '🫃 Bloating', value: _bloating, onChanged: (v) => setState(() => _bloating = v)),
                  _SymptomSlider(label: '😴 Fatigue', value: _fatigue, onChanged: (v) => setState(() => _fatigue = v)),
                  _SymptomSlider(label: '🔥 Acidity', value: _acidity, onChanged: (v) => setState(() => _acidity = v)),
                  _SymptomSlider(label: '⚡ Energy', value: _energy, onChanged: (v) => setState(() => _energy = v)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MealSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MealSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(data['name'] as String? ?? 'Meal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          if (data['macros'] != null) ...[
            const SizedBox(height: 10),
            const Text('Macros:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Calories: ${data['macros']['calories']} kcal  •  Protein: ${data['macros']['protein']}g'),
          ],
        ],
      ),
    );
  }
}

class _SymptomSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _SymptomSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(value.toInt().toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 5,
            divisions: 5,
            activeColor: AppColors.primaryTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

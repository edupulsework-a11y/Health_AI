import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:health_ai/services/health_service.dart';

class NutritionRings extends StatefulWidget {
  const NutritionRings({super.key});

  @override
  State<NutritionRings> createState() => _NutritionRingsState();
}

class _NutritionRingsState extends State<NutritionRings> {
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    _healthService.addListener(_update);
  }

  @override
  void dispose() {
    _healthService.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final data = _healthService.currentData;
    
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/ai-chat'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nutrition Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${data.calories.toInt()} / ${data.calorieGoal.toInt()} kcal', style: const TextStyle(color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRing(data.protein / data.proteinGoal, 'Protein', AppColors.primary, '${data.protein.toInt()}/${data.proteinGoal.toInt()}g'),
                _buildRing(data.carbs / data.carbsGoal, 'Carbs', AppColors.accent, '${data.carbs.toInt()}/${data.carbsGoal.toInt()}g'),
                _buildRing(data.fats / data.fatsGoal, 'Fats', AppColors.secondary, '${data.fats.toInt()}/${data.fatsGoal.toInt()}g'),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(child: _buildLinearStat(Icons.directions_walk_rounded, 'Steps', '${data.steps} / ${(data.stepGoal / 1000).toStringAsFixed(1)}k', data.steps / data.stepGoal, Colors.blue)),
                const SizedBox(width: 24),
                Expanded(child: _buildLinearStat(Icons.local_drink_rounded, 'Water', '${data.water.toStringAsFixed(1)} / ${data.waterGoal} L', data.water / data.waterGoal, Colors.cyan)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinearStat(IconData icon, String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildRing(double progress, String label, Color color, String value) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                color: color,
                backgroundColor: color.withOpacity(0.1),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }
}

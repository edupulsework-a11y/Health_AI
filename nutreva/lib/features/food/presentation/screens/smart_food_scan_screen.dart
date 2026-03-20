import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/firebase_sensor_service.dart';
import '../../data/services/ai_food_service.dart';

// ── State providers ───────────────────────────────────
final _loadingProvider = StateProvider<bool>((ref) => false);
final _resultProvider = StateProvider<FoodSafetyResult?>((ref) => null);

class SmartFoodScanScreen extends ConsumerStatefulWidget {
  const SmartFoodScanScreen({super.key});

  @override
  ConsumerState<SmartFoodScanScreen> createState() => _SmartFoodScanScreenState();
}

class _SmartFoodScanScreenState extends ConsumerState<SmartFoodScanScreen> {
  final _nameCtrl = TextEditingController();
  XFile? _pickedImage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _analyse() async {
    if (_pickedImage == null || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add image and food name')),
      );
      return;
    }

    ref.read(_loadingProvider.notifier).state = true;
    ref.read(_resultProvider.notifier).state = null;

    try {
      // Get latest sensor reading
      final sensor = await FirebaseSensorService().fetchOnce();
      // Call Gemini AI
      final result = await ref.read(aiServiceProvider).analyseFoodSafety(
            imageFile: File(_pickedImage!.path),
            foodName: _nameCtrl.text.trim(),
            sensor: sensor,
          );
      ref.read(_resultProvider.notifier).state = result;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      ref.read(_loadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorAsync = ref.watch(sensorDataProvider);
    final loading = ref.watch(_loadingProvider);
    final result = ref.watch(_resultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Food Safety AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Live Sensor Card ─────────────────────
            sensorAsync.when(
              data: (s) => _LiveSensorCard(sensor: s),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const _SensorOfflineCard(),
            ),
            const SizedBox(height: 20),

            // ── Image Picker ─────────────────────────
            const Text('Step 1: Add Food Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ImageOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(_pickedImage!.path),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Food Name ────────────────────────────
            const Text('Step 2: Enter Food Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'e.g. Paneer, Apple, Leftover Rice...',
                prefixIcon: Icon(Icons.restaurant_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // ── Analyse Button ───────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(loading ? 'Analysing with AI...' : 'Check Food Safety',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: loading ? null : _analyse,
              ),
            ),
            const SizedBox(height: 24),

            // ── Result ───────────────────────────────
            if (result != null) _FoodSafetyResultCard(result: result),
          ],
        ),
      ),
    );
  }
}

// ── Sub-Widgets ───────────────────────────────────────

class _LiveSensorCard extends StatelessWidget {
  final SensorData sensor;
  const _LiveSensorCard({required this.sensor});

  Color get _statusColor {
    switch (sensor.safetyStatus) {
      case 'Good':
        return AppColors.success;
      case 'Moderate':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors_rounded, color: _statusColor),
              const SizedBox(width: 8),
              const Text('Live IoT Reading',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(sensor.safetyStatus,
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SensorPill(
                  icon: Icons.thermostat_rounded,
                  value: '${sensor.temperature.toStringAsFixed(1)}°C',
                  label: 'Temp'),
              _SensorPill(
                  icon: Icons.water_drop_outlined,
                  value: '${sensor.humidity.toStringAsFixed(0)}%',
                  label: 'Humidity'),
              _SensorPill(
                  icon: Icons.air_rounded,
                  value: '${sensor.gasPpm} ppm',
                  label: 'Gas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorOfflineCard extends StatelessWidget {
  const _SensorOfflineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'ESP8266 offline — AI will analyse image & food name only',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorPill extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _SensorPill(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

class _ImageOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImageOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryTeal.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _FoodSafetyResultCard extends StatelessWidget {
  final FoodSafetyResult result;
  const _FoodSafetyResultCard({required this.result});

  Color get _color {
    switch (result.verdict) {
      case 'Safe':
        return AppColors.success;
      case 'Moderate':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (result.verdict) {
      case 'Safe':
        return Icons.check_circle_rounded;
      case 'Moderate':
        return Icons.warning_amber_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Food is ${result.verdict}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _color)),
                    Text(
                        'Confidence: ${(result.confidenceScore * 100).toStringAsFixed(0)}%',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(result.explanation, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('Tips:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...result.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right_rounded, color: _color, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(tip, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          const Text(
              '⚠️ AI analysis is indicative. Use your judgement.',
              style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';

// State is tracked locally inside each ConsumerStatefulWidget below

class FoodTabScreen extends ConsumerStatefulWidget {
  const FoodTabScreen({super.key});

  @override
  ConsumerState<FoodTabScreen> createState() => _FoodTabScreenState();
}

class _FoodTabScreenState extends ConsumerState<FoodTabScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Food Intelligence'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primaryTeal,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt_rounded), text: 'Fresh'),
            Tab(icon: Icon(Icons.sensors_rounded), text: 'IoT'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Label'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _FreshFoodTab(),
          _HardwareFoodTab(),
          _LabelScannerTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────── TAB 1 — Fresh Food ────────────────────────────
class _FreshFoodTab extends ConsumerStatefulWidget {
  const _FreshFoodTab();
  @override
  ConsumerState<_FreshFoodTab> createState() => _FreshFoodTabState();
}

class _FreshFoodTabState extends ConsumerState<_FreshFoodTab> {
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController();
  XFile? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    setState(() => _image = file);
  }

  Future<void> _analyze() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulated
    setState(() {
      _loading = false;
      _result = {
        'calories': 245,
        'carbs': 32.4,
        'fat': 8.1,
        'protein': 14.2,
      };
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryTeal.withAlpha(80), width: 1.5),
              ),
              child: _image == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 40, color: AppColors.primaryTeal),
                        SizedBox(height: 8),
                        Text('Upload food image',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_image!.path), fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Food Name',
              prefixIcon: Icon(Icons.restaurant_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _gramsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Grams',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: const Icon(Icons.search_rounded),
              label: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Analyse'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _NutritionCard(data: _result!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Log Meal'),
                onPressed: () => context.push('/meal-log', extra: {
                  'name': _nameCtrl.text,
                  'macros': _result,
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── TAB 2 — Hardware / IoT ─────────────────────────
class _HardwareFoodTab extends ConsumerStatefulWidget {
  const _HardwareFoodTab();
  @override
  ConsumerState<_HardwareFoodTab> createState() => _HardwareFoodTabState();
}

class _HardwareFoodTabState extends ConsumerState<_HardwareFoodTab> {
  XFile? _image;
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _status;
  Map<String, dynamic>? _sensorData;

  Future<void> _fetchSensor() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _loading = false;
      _sensorData = {'temperature': 26.2, 'humidity': 58.0, 'gas': 145};
    });
  }

  Future<void> _analyzeWithSensor() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _status = 'Good';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _status == 'Good'
        ? AppColors.success
        : _status == 'Moderate'
            ? AppColors.warning
            : AppColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sensors_rounded),
                  label: const Text('Fetch Sensor'),
                  onPressed: _loading ? null : _fetchSensor,
                ),
              ),
            ],
          ),
          if (_sensorData != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SensorValue(label: 'Temp', value: '${_sensorData!['temperature']}°C', icon: Icons.thermostat_rounded),
                  _SensorValue(label: 'Humidity', value: '${_sensorData!['humidity']}%', icon: Icons.water_drop_outlined),
                  _SensorValue(label: 'Gas ppm', value: '${_sensorData!['gas']}', icon: Icons.air_rounded),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Food Name',
              prefixIcon: Icon(Icons.restaurant_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_loading || _sensorData == null) ? null : _analyzeWithSensor,
              icon: const Icon(Icons.biotech_rounded),
              label: _loading
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ML Analysis'),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: statusColor, size: 40),
                  const SizedBox(height: 8),
                  Text('Food Status: $_status',
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Log Meal'),
                onPressed: () => context.push('/meal-log', extra: {'name': _nameCtrl.text}),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorValue extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SensorValue({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────── TAB 3 — Label Scanner ──────────────────────────
class _LabelScannerTab extends ConsumerStatefulWidget {
  const _LabelScannerTab();
  @override
  ConsumerState<_LabelScannerTab> createState() => _LabelScannerTabState();
}

class _LabelScannerTabState extends ConsumerState<_LabelScannerTab> {
  XFile? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickAndScan() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _image = file;
      _loading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _result = {
        'sugar': 'High (24g)',
        'sodium': 'Moderate (480mg)',
        'additives': 'Low Risk',
        'score': 65,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndScan,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentViolet.withAlpha(80), width: 1.5),
              ),
              child: _image == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 48, color: AppColors.accentViolet),
                        SizedBox(height: 8),
                        Text('Tap to scan food label', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : _loading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.accentViolet),
                            SizedBox(height: 12),
                            Text('Analysing label with AI...', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(_image!.path), fit: BoxFit.cover)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _LabelResultCard(data: _result!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Log Meal'),
                onPressed: () => context.push('/meal-log', extra: {'label_data': _result}),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NutritionCard({required this.data});

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
          const Text('Nutrition Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroTile(label: 'Calories', value: '${data['calories']} kcal', color: AppColors.accentAmber),
              _MacroTile(label: 'Carbs', value: '${data['carbs']}g', color: AppColors.info),
              _MacroTile(label: 'Fat', value: '${data['fat']}g', color: AppColors.accentPink),
              _MacroTile(label: 'Protein', value: '${data['protein']}g', color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class _LabelResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LabelResultCard({required this.data});

  Color _scoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final score = data['score'] as int;
    final color = _scoreColor(score);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Safety Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$score/100', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabelRow(label: 'Sugar Level', value: '${data['sugar']}', icon: Icons.water_drop_rounded),
          _LabelRow(label: 'Sodium Level', value: '${data['sodium']}', icon: Icons.grain_rounded),
          _LabelRow(label: 'Additive Risk', value: '${data['additives']}', icon: Icons.science_outlined),
          const SizedBox(height: 8),
          const Text('⚠️ This is an AI analysis. Consult a nutritionist for medical advice.',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _LabelRow({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryTeal),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

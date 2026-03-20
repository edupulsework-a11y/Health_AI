import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/dual_ai_service.dart';

class MenstrualScreen extends ConsumerStatefulWidget {
  const MenstrualScreen({super.key});

  @override
  ConsumerState<MenstrualScreen> createState() => _MenstrualScreenState();
}

class _MenstrualScreenState extends ConsumerState<MenstrualScreen> {
  final _ai = DualAiService();
  final _symptoms = ['Cramps', 'Headache', 'Bloating', 'Mood Swings', 'Fatigue', 'Backache', 'Nausea'];
  final Set<String> _selectedSymptoms = {};
  bool _isPrivacyEnabled = true;
  bool _isAILoading = false;
  String _aiAdvice = "Tap the card to generate AI advice based on your current phase and symptoms.";

  int _cycleLength = 28;
  int _periodLength = 5;
  int _currentDay = 1;
  DateTime? _lastPeriodStart;
  bool _hasOnboarded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasOnboarded) _showOnboarding();
    });
  }

  void _calculateCurrentDay() {
    if (_lastPeriodStart != null) {
      final diff = DateTime.now().difference(_lastPeriodStart!).inDays;
      setState(() => _currentDay = (diff % _cycleLength) + 1);
    }
  }

  String get _phase {
    if (_currentDay <= _periodLength) return "Menstrual Phase";
    if (_currentDay > 13 && _currentDay < 17) return "Ovulation Phase";
    if (_currentDay >= 17) return "Luteal Phase";
    return "Follicular Phase";
  }

  Color get _phaseColor {
    switch (_phase) {
      case "Menstrual Phase": return Colors.red.shade400;
      case "Ovulation Phase": return Colors.green.shade400;
      case "Luteal Phase": return Colors.purple.shade400;
      default: return Colors.blue.shade400;
    }
  }

  void _showOnboarding() {
    DateTime tempDate = DateTime.now().subtract(const Duration(days: 14));
    int tempCycle = 28;
    int tempPeriod = 5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.water_drop_rounded, color: Colors.pink),
            SizedBox(width: 8),
            Text('Cycle Setup', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Tell us about your cycle for accurate tracking:'),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Last Period Start Date'),
                subtitle: Text("${tempDate.day}/${tempDate.month}/${tempDate.year}",
                    style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.calendar_today_rounded, color: Colors.pink),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: tempDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                    builder: (_, child) => Theme(
                      data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Colors.pink)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDs(() => tempDate = picked);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '28',
                decoration: InputDecoration(
                  labelText: 'Avg Cycle Length (days)',
                  prefixIcon: const Icon(Icons.loop_rounded, color: Colors.pink),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => tempCycle = int.tryParse(v) ?? 28,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '5',
                decoration: InputDecoration(
                  labelText: 'Avg Period Duration (days)',
                  prefixIcon: const Icon(Icons.calendar_view_day_rounded, color: Colors.pink),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => tempPeriod = int.tryParse(v) ?? 5,
              ),
            ]),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _lastPeriodStart = tempDate;
                  _cycleLength = tempCycle;
                  _periodLength = tempPeriod;
                  _hasOnboarded = true;
                  _calculateCurrentDay();
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getAIAdvice() async {
    setState(() => _isAILoading = true);
    try {
      final advice = await _ai.getCycleAdvice(
        currentDay: _currentDay,
        cycleLength: _cycleLength,
        periodLength: _periodLength,
        symptoms: _selectedSymptoms.toList(),
      );
      if (mounted) setState(() => _aiAdvice = advice);
    } catch (e) {
      if (mounted) setState(() => _aiAdvice = "Could not fetch advice. Check your connection.");
    } finally {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menstrual Health'),
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () => _showOnboarding()),
          Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 16),
            Switch(
              value: _isPrivacyEnabled,
              onChanged: (v) => setState(() => _isPrivacyEnabled = v),
              activeTrackColor: Colors.pink.withAlpha(80),
              thumbColor: WidgetStateProperty.all(Colors.pink),
            ),
          ]),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cycle card ─────────────────────────
            _buildCycleCard(),
            const SizedBox(height: 24),

            // ── 7-day timeline ─────────────────────
            _buildTimeline(),
            const SizedBox(height: 24),

            // ── Symptoms ──────────────────────────
            const Text('How are you feeling today?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _symptoms.map((s) {
                final selected = _selectedSymptoms.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (v) => setState(() => v ? _selectedSymptoms.add(s) : _selectedSymptoms.remove(s)),
                  selectedColor: Colors.pink.withAlpha(40),
                  checkmarkColor: Colors.pink,
                  side: BorderSide(color: selected ? Colors.pink : Colors.grey.withAlpha(60)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── AI advice ──────────────────────────
            _buildAICard(),
            const SizedBox(height: 24),

            // ── Nutrient focus ─────────────────────
            _buildNutrients(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCard() {
    final nextPeriod = _lastPeriodStart?.add(Duration(days: _cycleLength)) ??
        DateTime.now().add(const Duration(days: 10));
    final daysToNext = nextPeriod.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_phaseColor.withAlpha(30), Colors.pink.shade50],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _phaseColor.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Day $_currentDay of $_cycleLength',
                  style: TextStyle(color: _phaseColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(_phase, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(daysToNext > 0 ? 'Next period in $daysToNext days' : 'Period may start today',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _phaseColor.withAlpha(30), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.water_drop_rounded, color: _phaseColor, size: 32),
            ),
          ]),
          const SizedBox(height: 20),
          // Cycle progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _currentDay / _cycleLength,
              minHeight: 10,
              backgroundColor: _phaseColor.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Day 1', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text('Day $_cycleLength', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (_, i) {
          final dayNum = _currentDay - 3 + i;
          final isToday = dayNum == _currentDay;
          final isPeriod = dayNum > 0 && dayNum <= _periodLength;
          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Text(dayNum > 0 ? 'D$dayNum' : '',
                    style: TextStyle(fontSize: 11,
                        color: isToday ? Colors.pink : Colors.grey,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.pink : (isPeriod ? Colors.pink.withAlpha(30) : Colors.grey.withAlpha(15)),
                    shape: BoxShape.circle,
                    boxShadow: isToday ? [BoxShadow(color: Colors.pink.withAlpha(80), blurRadius: 10)] : null,
                    border: Border.all(color: isToday ? Colors.pink : (isPeriod ? Colors.pink.withAlpha(100) : Colors.grey.withAlpha(30))),
                  ),
                  child: Center(
                    child: dayNum > 0
                        ? Text('$dayNum',
                            style: TextStyle(
                                color: isToday ? Colors.white : (isPeriod ? Colors.pink : Colors.black54),
                                fontWeight: FontWeight.bold, fontSize: 13))
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAICard() {
    return GestureDetector(
      onTap: _isAILoading ? null : _getAIAdvice,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.pink.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.pink.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.pink, size: 20),
              const SizedBox(width: 8),
              const Text('AI Food & Activity Advice', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_isAILoading) ...[ const Spacer(),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink)) ],
            ]),
            const SizedBox(height: 12),
            Text(_aiAdvice, style: const TextStyle(fontSize: 13, height: 1.6)),
            if (!_isAILoading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Tap to refresh', style: TextStyle(fontSize: 11, color: Colors.pink.shade400, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nutrient Focus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _nutrientBar('Iron', _currentDay <= _periodLength ? 0.9 : 0.6, Colors.redAccent),
        const SizedBox(height: 10),
        _nutrientBar('Magnesium', 0.4, Colors.purpleAccent),
        const SizedBox(height: 10),
        _nutrientBar('Calcium', 0.65, Colors.blue),
        const SizedBox(height: 10),
        _nutrientBar('Vitamin D', 0.5, Colors.orange),
      ],
    );
  }

  Widget _nutrientBar(String label, double value, Color color) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value, minHeight: 8,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

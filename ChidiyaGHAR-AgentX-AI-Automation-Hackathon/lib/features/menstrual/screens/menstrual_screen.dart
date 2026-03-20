import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api_keys.dart';
import 'package:google_fonts/google_fonts.dart';

class MenstrualModule extends StatefulWidget {
  const MenstrualModule({super.key});

  @override
  State<MenstrualModule> createState() => _MenstrualModuleState();
}

class _MenstrualModuleState extends State<MenstrualModule> {
  final List<String> _symptoms = ['Cramps', 'Headache', 'Bloating', 'Mood Swings', 'Fatigue'];
  final Set<String> _selectedSymptoms = {};
  bool _isPrivacyEnabled = true;
  bool _isAILoading = false;
  String _aiAdvice = "Tap to generate AI advice based on your current phase and symptoms.";

  // New Dynamic States
  int _cycleLength = 28;
  int _periodLength = 5;
  int _currentDay = 1; // Default
  DateTime? _lastPeriodStart;
  bool _hasOnboarded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasOnboarded) {
        _showOnboardingQuiz();
      }
    });
  }

  void _calculateCurrentDay() {
    if (_lastPeriodStart != null) {
      final difference = DateTime.now().difference(_lastPeriodStart!).inDays;
      setState(() {
        _currentDay = (difference % _cycleLength) + 1;
      });
    }
  }

  void _showOnboardingQuiz() {
    DateTime tempDate = DateTime.now().subtract(const Duration(days: 14));
    int tempCycle = 28;
    int tempPeriod = 5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Menstrual Onboarding', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('To provide accurate predictions, we need a few details:'),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Last Period Start Date'),
                  subtitle: Text("${tempDate.day}/${tempDate.month}/${tempDate.year}"),
                  trailing: const Icon(Icons.calendar_today_rounded, color: Colors.pink),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => tempDate = picked);
                    }
                  },
                ),
                TextFormField(
                  initialValue: '28',
                  decoration: const InputDecoration(labelText: 'Avg Cycle Length (days)'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => tempCycle = int.tryParse(val) ?? 28,
                ),
                TextFormField(
                  initialValue: '5',
                  decoration: const InputDecoration(labelText: 'Avg Period Duration (days)'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => tempPeriod = int.tryParse(val) ?? 5,
                ),
              ],
            ),
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
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
              child: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    int tempCycle = _cycleLength;
    int tempPeriod = _periodLength;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cycle Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _cycleLength.toString(),
              decoration: const InputDecoration(labelText: 'Cycle Length (days)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => tempCycle = int.tryParse(val) ?? 28,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _periodLength.toString(),
              decoration: const InputDecoration(labelText: 'Period Duration (days)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => tempPeriod = int.tryParse(val) ?? 5,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cycleLength = tempCycle;
                _periodLength = tempPeriod;
              });
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _getAIAdvice() async {
    setState(() => _isAILoading = true);
    
    String phase = "Follicular Phase";
    if (_currentDay <= _periodLength) phase = "Menstrual Phase";
    else if (_currentDay > 13 && _currentDay < 17) phase = "Ovulation Phase";
    else if (_currentDay >= 17) phase = "Luteal Phase";

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
            {
              'role': 'system',
              'content': 'You are a specialized women health advisor. Provide empathetic and professional nutritional and activity tips.'
            },
            {
              'role': 'user',
              'content': 'Patient is on Day $_currentDay of her $_cycleLength-day cycle (Phase: $phase). \n'
                         'Current Symptoms: ${_selectedSymptoms.join(', ')}. \n'
                         '1. Provide 2-3 specific nutritional and activity tips to manage these symptoms and improve wellness during this phase.\n'
                         '2. Predict the next period start date based on the cycle length.'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiAdvice = data['choices'][0]['message']['content'];
        });
      }
    } catch (e) {
      setState(() => _aiAdvice = "Could not fetch advice. Please check your connection.");
    } finally {
      setState(() => _isAILoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menstrual Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsDialog,
          ),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16),
              Switch(
                value: _isPrivacyEnabled,
                onChanged: (val) => setState(() => _isPrivacyEnabled = val),
                activeColor: Colors.pink,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCycleTimeline(),
            const SizedBox(height: 32),
            const Text('How are you feeling today?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptoms.map((s) {
                final isSelected = _selectedSymptoms.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) _selectedSymptoms.add(s);
                      else _selectedSymptoms.remove(s);
                    });
                  },
                  selectedColor: Colors.pink.withOpacity(0.2),
                  checkmarkColor: Colors.pink,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildAIRecommendation(),
            const SizedBox(height: 32),
            _buildNutrientTracking(),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleTimeline() {
    String phase = "Follicular Phase";
    if (_currentDay <= _periodLength) phase = "Menstrual Phase";
    else if (_currentDay > 13 && _currentDay < 17) phase = "Ovulation Phase";
    else if (_currentDay >= 17) phase = "Luteal Phase";

    final nextPeriod = _lastPeriodStart?.add(Duration(days: _cycleLength)) ?? DateTime.now().add(const Duration(days: 10));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.pink.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Day $_currentDay of $_cycleLength', style: const TextStyle(fontSize: 14, color: Colors.pink, fontWeight: FontWeight.bold, letterSpacing: 1)),
                   Text(phase, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                 ],
               ),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                 child: const Icon(Icons.water_drop_rounded, color: Colors.pink, size: 30),
               ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = (_currentDay - 3 + index);
              final isToday = dayNum == _currentDay;
              final isPeriod = dayNum <= _periodLength && dayNum > 0;

              return Column(
                children: [
                  Text(dayNum > 0 ? 'D$dayNum' : '', style: TextStyle(fontSize: 12, color: isToday ? Colors.pink : Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.pink : (isPeriod ? Colors.pink.withOpacity(0.1) : Colors.white),
                      shape: BoxShape.circle,
                      boxShadow: isToday ? [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10)] : null,
                      border: Border.all(color: isToday ? Colors.pink : (isPeriod ? Colors.pink : Colors.grey.shade200)),
                    ),
                    child: Center(
                      child: dayNum > 0 ? Text(
                        '$dayNum',
                        style: TextStyle(
                            color: isToday ? Colors.white : (isPeriod ? Colors.pink : Colors.black87), 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                        ),
                      ) : null,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Text(
                'Predicted Next Period: ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                '${nextPeriod.day} ${_getMonthName(nextPeriod.month)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  Widget _buildAIRecommendation() {
    return InkWell(
      onTap: _isAILoading ? null : _getAIAdvice,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('AI Food & Activity Advice', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isAILoading) ...[
                  const Spacer(),
                  const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                ]
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiAdvice,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (!_isAILoading && _aiAdvice.startsWith('Tap')) 
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Tap to refresh', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nutrient Focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildNutrientProgress('Iron', _currentDay <= _periodLength ? 0.9 : 0.6, Colors.redAccent),
        const SizedBox(height: 12),
        _buildNutrientProgress('Magnesium', 0.4, Colors.purpleAccent),
      ],
    );
  }

  Widget _buildNutrientProgress(String label, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          color: color,
          backgroundColor: color.withOpacity(0.1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

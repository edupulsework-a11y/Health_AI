import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class WeekInfo {
  final int week;
  final String babySize;
  final String babyFact;
  final String motherTip;

  const WeekInfo(this.week, this.babySize, this.babyFact, this.motherTip);
}

const List<WeekInfo> _weekData = [
  WeekInfo(4,  'Poppy seed',   'Embryo has just implanted. Heart cells are forming.',             'Take folic acid. Avoid alcohol completely.'),
  WeekInfo(6,  'Lentil',       'Heart is beating ~100 bpm. Tiny arm and leg buds appear.',        'You may notice nausea. Eat small, frequent meals.'),
  WeekInfo(8,  'Raspberry',    'All major organs are forming. Baby is ~1.6 cm.',                  'Fatigue is normal. Rest whenever you can.'),
  WeekInfo(10, 'Prune',        'Fingers and toes are fully separated. Baby can swallow.',          'First prenatal visit if not done yet.'),
  WeekInfo(12, 'Lime',         'Kidneys produce urine. Reflexes are developing.',                  'NT scan done around now. First trimester almost over!'),
  WeekInfo(14, 'Lemon',        'Baby can make facial expressions. Sucking reflex starts.',         'Energy levels may improve. Gentle exercise is great.'),
  WeekInfo(16, 'Avocado',      'Baby hears sounds and light. Skeleton ossifying.',                 'Start sleeping on your left side.'),
  WeekInfo(18, 'Sweet potato', 'Baby yawns and hiccups! Unique fingerprints formed.',              'Anatomy scan (20 weeks) coming soon.'),
  WeekInfo(20, 'Banana',        'You may feel kicks now! Baby weighs ~300 g.',                     'Halfway! Celebrate this milestone. Rest well.'),
  WeekInfo(22, 'Papaya',        'Sense of touch is developing. Eyelids and brows visible.',        'Watch for swelling. Stay hydrated.'),
  WeekInfo(24, 'Ear of corn',   'Viability milestone! Brain developing rapidly.',                  'Glucose tolerance test this week. Increase iron-rich foods.'),
  WeekInfo(26, 'Lettuce head',  'Eyes begin to open. Baby responds to your voice.',                'Prenatal yoga can ease back pain.'),
  WeekInfo(28, 'Eggplant',     'Brain has billions of neurons. Baby practices breathing.',          'Third trimester begins! Kick counts start now.'),
  WeekInfo(30, 'Cabbage',      'Eyes can focus. Baby accumulates body fat.',                       'Sleep on left side. Prepare hospital bag.'),
  WeekInfo(32, 'Squash',       'Baby weighs ~1.8 kg. Toenails and fingernails visible.',           'Practice Braxton Hicks are normal.'),
  WeekInfo(34, 'Butternut sq.','Baby is gaining 200 g/week. Lungs nearly mature.',                'Take childbirth classes now.'),
  WeekInfo(36, 'Honeydew',     'Baby is "full term" at 37 weeks. Head may engage.',               'Pack hospital bag! Birth can happen any week now.'),
  WeekInfo(38, 'Watermelon',   'Baby weighs ~3 kg. Skull bones not yet fused.',                   'Watch for labour signs: contractions, water breaking.'),
  WeekInfo(40, 'Pumpkin',      'Full term! Average birth weight 3–3.5 kg.',                       'Baby can arrive any day. Stay calm and trust your body.'),
];

WeekInfo _infoForWeek(int w) {
  return _weekData.lastWhere((e) => e.week <= w, orElse: () => _weekData.first);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MaternityScreen extends StatefulWidget {
  const MaternityScreen({super.key});

  @override
  State<MaternityScreen> createState() => _MaternityScreenState();
}

class _MaternityScreenState extends State<MaternityScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabs;

  // ── Pregnancy state ──────────────────────────────────────────
  DateTime? _lmpDate;       // Last menstrual period
  int _currentWeek = 0;
  int _daysLeft = 280;
  bool _hasOnboarded = false;
  bool _isDelivered = false;
  DateTime? _deliveryDate;

  // ── Mother vitals ─────────────────────────────────────────────
  final _weightCtrl = TextEditingController();
  final _bpCtrl     = TextEditingController();
  final _kicksCtrl  = TextEditingController();
  List<Map<String, dynamic>> _vitalLogs = [];

  // ── Baby (post-delivery) ──────────────────────────────────────
  final _babyWeightCtrl = TextEditingController();
  final _babyHeightCtrl = TextEditingController();
  List<Map<String, dynamic>> _babyLogs = [];

  // ── AI advice ─────────────────────────────────────────────────
  String _aiAdvice = 'Tap to get AI advice for your current week.';
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _isDelivered ? 2 : 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasOnboarded) _showOnboarding();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────
  void _showOnboarding() {
    DateTime tempLmp = DateTime.now().subtract(const Duration(days: 56));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Text('🤰', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Maternity Setup', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('When was the first day of your last period (LMP)?', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('LMP Date'),
              subtitle: Text(
                '${tempLmp.day}/${tempLmp.month}/${tempLmp.year}',
                style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_month_rounded, color: Colors.pink),
              onTap: () async {
                final p = await showDatePicker(
                  context: ctx,
                  initialDate: tempLmp,
                  firstDate: DateTime.now().subtract(const Duration(days: 280)),
                  lastDate: DateTime.now(),
                );
                if (p != null) setDs(() => tempLmp = p);
              },
            ),
          ]),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _lmpDate = tempLmp;
                  final diff = DateTime.now().difference(tempLmp).inDays;
                  _currentWeek = (diff / 7).floor().clamp(1, 42);
                  _daysLeft = (280 - diff).clamp(0, 280);
                  _hasOnboarded = true;
                  _tabs = TabController(length: 1, vsync: this);
                });
                Navigator.pop(ctx);
                _fetchLogs();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
              child: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data ────────────────────────────────────────────────────────────────────
  Future<void> _fetchLogs() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final v = await _supabase.from('maternity_vitals').select()
          .eq('user_id', uid).order('recorded_at', ascending: false).limit(10);
      final b = await _supabase.from('baby_logs').select()
          .eq('user_id', uid).order('recorded_at', ascending: false).limit(10);
      if (mounted) setState(() {
        _vitalLogs = List<Map<String, dynamic>>.from(v);
        _babyLogs  = List<Map<String, dynamic>>.from(b);
      });
    } catch (_) {}
  }

  Future<void> _saveVital() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final w = double.tryParse(_weightCtrl.text);
    final k = int.tryParse(_kicksCtrl.text);
    final bp = _bpCtrl.text.trim();
    if (w == null && bp.isEmpty && k == null) return;
    try {
      await _supabase.from('maternity_vitals').insert({
        'user_id': uid,
        'week': _currentWeek,
        'weight_kg': w,
        'blood_pressure': bp.isNotEmpty ? bp : null,
        'kick_count': k,
        'recorded_at': DateTime.now().toIso8601String(),
      });
      _weightCtrl.clear(); _bpCtrl.clear(); _kicksCtrl.clear();
      _fetchLogs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Vital saved!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveBabyLog() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final w = double.tryParse(_babyWeightCtrl.text);
    final h = double.tryParse(_babyHeightCtrl.text);
    if (w == null && h == null) return;
    try {
      await _supabase.from('baby_logs').insert({
        'user_id': uid,
        'weight_kg': w,
        'height_cm': h,
        'recorded_at': DateTime.now().toIso8601String(),
      });
      _babyWeightCtrl.clear(); _babyHeightCtrl.clear();
      _fetchLogs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Baby log saved!')));
    } catch (e) {}
  }

  Future<void> _getAiAdvice() async {
    setState(() { _aiLoading = true; });
    final info = _infoForWeek(_currentWeek);
    try {
      final resp = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.grokApiKey}',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an empathetic OB-GYN assistant. Provide concise, safe pregnancy advice.',
            },
            {
              'role': 'user',
              'content': 'Week $_currentWeek of pregnancy. Baby is size of ${info.babySize}. '
                  'Give 3 practical tips covering nutrition, exercise, and emotional well-being. Be supportive and brief.',
            }
          ],
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _aiAdvice = data['choices'][0]['message']['content'].toString().trim());
      }
    } catch (_) {
      setState(() => _aiAdvice = 'Could not fetch advice. Please check your connection.');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  void _markDelivered() {
    setState(() {
      _isDelivered = true;
      _deliveryDate = DateTime.now();
      _tabs = TabController(length: 2, vsync: this);
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maternity Care'),
        actions: [
          if (!_isDelivered)
            TextButton.icon(
              icon: const Icon(Icons.child_friendly_rounded, color: Colors.pink, size: 18),
              label: const Text('Delivered!', style: TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Congratulations! 🎉'),
                  content: const Text('Mark your baby as delivered? This will switch you to the post-delivery tracking mode.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not yet')),
                    ElevatedButton(
                      onPressed: () { Navigator.pop(context); _markDelivered(); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                      child: const Text('Yes!', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          if (_isDelivered) ...[
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: const [Tab(text: '👩 Mother'), Tab(text: '👶 Baby')],
              labelColor: Colors.pink,
              indicatorColor: Colors.pink,
            ),
          ],
        ],
        bottom: _isDelivered ? TabBar(
          controller: _tabs,
          tabs: const [Tab(text: '👩 Mother'), Tab(text: '👶 Baby')],
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink,
        ) : null,
      ),
      body: _isDelivered
          ? TabBarView(
              controller: _tabs,
              children: [_buildPostDeliveryMother(), _buildBabyTracker()],
            )
          : _buildPregnancyView(),
    );
  }

  // ── PREGNANCY VIEW ──────────────────────────────────────────────────────────
  Widget _buildPregnancyView() {
    if (!_hasOnboarded) return const Center(child: CircularProgressIndicator());
    final info = _infoForWeek(_currentWeek);
    final trimester = _currentWeek <= 12 ? '1st Trimester' : (_currentWeek <= 27 ? '2nd Trimester' : '3rd Trimester');
    final trimColor = _currentWeek <= 12 ? Colors.blue : (_currentWeek <= 27 ? Colors.orange : Colors.pink);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero progress card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade700, Colors.pink.shade300],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Week $_currentWeek of 40',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text(trimester,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_daysLeft days to due date',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
                Column(children: [
                  Text('🍼', style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 4),
                  Text(info.babySize,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ]),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _currentWeek / 40,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                Text('Week 1', style: TextStyle(color: Colors.white60, fontSize: 10)),
                Text('Week 40', style: TextStyle(color: Colors.white60, fontSize: 10)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Trimester chips ────────────────────────────────────
          Row(children: [
            _TrimChip('T1 Wk 1–12', Colors.blue, _currentWeek >= 1 && _currentWeek <= 12),
            const SizedBox(width: 8),
            _TrimChip('T2 Wk 13–27', Colors.orange, _currentWeek >= 13 && _currentWeek <= 27),
            const SizedBox(width: 8),
            _TrimChip('T3 Wk 28–40', Colors.pink, _currentWeek >= 28),
          ]),
          const SizedBox(height: 20),

          // ── Baby this week ─────────────────────────────────────
          _infoCard('👶 Baby This Week', [
            _row('Size', info.babySize),
            const SizedBox(height: 8),
            Text(info.babyFact, style: const TextStyle(fontSize: 13, height: 1.5)),
          ], Colors.pink),
          const SizedBox(height: 16),

          // ── Mother tip ─────────────────────────────────────────
          _infoCard('💡 Tip for You', [
            Text(info.motherTip, style: const TextStyle(fontSize: 13, height: 1.5)),
          ], Colors.purple),
          const SizedBox(height: 16),

          // ── Week picker ────────────────────────────────────────
          _infoCard('📅 Adjust Pregnancy Week', [
            Row(children: [
              Expanded(
                child: Slider(
                  value: _currentWeek.toDouble(),
                  min: 1, max: 40,
                  divisions: 39,
                  activeColor: Colors.pink,
                  label: 'Week $_currentWeek',
                  onChanged: (v) => setState(() => _currentWeek = v.toInt()),
                ),
              ),
              Text('Wk $_currentWeek', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
            ]),
          ], Colors.grey),
          const SizedBox(height: 16),

          // ── Log vitals ─────────────────────────────────────────
          _infoCard('📊 Log Vitals Today', [
            _inputField(_weightCtrl, 'Weight (kg)', '65.5', Icons.monitor_weight_rounded),
            const SizedBox(height: 10),
            _inputField(_bpCtrl, 'Blood Pressure', '120/80', Icons.favorite_rounded),
            const SizedBox(height: 10),
            _inputField(_kicksCtrl, 'Baby Kicks (10 min)', '5', Icons.child_care_rounded, type: TextInputType.number),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Vitals'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveVital,
              ),
            ),
          ], AppColors.primaryTeal),
          const SizedBox(height: 16),

          // ── AI advice ──────────────────────────────────────────
          GestureDetector(
            onTap: _aiLoading ? null : _getAiAdvice,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.pink.withAlpha(10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.pink.withAlpha(60)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.pink, size: 18),
                  const SizedBox(width: 8),
                  const Text('AI Advice for Week', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_aiLoading) ...[
                    const Spacer(),
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink)),
                  ],
                ]),
                const SizedBox(height: 10),
                Text(_aiAdvice, style: const TextStyle(fontSize: 13, height: 1.6)),
                if (!_aiLoading)
                  const Padding(padding: EdgeInsets.only(top: 6),
                      child: Text('Tap to refresh', style: TextStyle(color: Colors.pink, fontSize: 11, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Past vitals ────────────────────────────────────────
          if (_vitalLogs.isNotEmpty) ...[
            const Text('📋 Vital History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ..._vitalLogs.take(5).map((v) => _VitalLogTile(v)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── POST-DELIVERY MOTHER ────────────────────────────────────────────────────
  Widget _buildPostDeliveryMother() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Recovery status
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.pink.shade700, Colors.pink.shade300]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎊 Postpartum Recovery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            if (_deliveryDate != null)
              Text(
                'Day ${DateTime.now().difference(_deliveryDate!).inDays} since delivery',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            const SizedBox(height: 10),
            const Text('Track your recovery, nutrition, and emotional health.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 20),

        // Postpartum checklist
        _infoCard('✅ Postpartum Checklist', [
          _checkItem('6-week postpartum check-up'),
          _checkItem('Pelvic floor exercises'),
          _checkItem('Iron & calcium supplements'),
          _checkItem('Mental health check (Edinburgh scale)'),
          _checkItem('Breastfeeding support if needed'),
        ], Colors.pink),
        const SizedBox(height: 16),

        // Log mother vitals
        _infoCard('📊 Log Daily Health', [
          _inputField(_weightCtrl, 'Weight (kg)', '62.0', Icons.monitor_weight_rounded),
          const SizedBox(height: 10),
          _inputField(_bpCtrl, 'Blood Pressure', '120/80', Icons.favorite_rounded),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveVital,
            ),
          ),
        ], AppColors.primaryTeal),
        const SizedBox(height: 16),

        // AI postpartum advice
        GestureDetector(
          onTap: _aiLoading ? null : () async {
            setState(() => _aiLoading = true);
            try {
              final resp = await http.post(
                Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${AppConstants.grokApiKey}',
                },
                body: jsonEncode({
                  'model': 'llama-3.3-70b-versatile',
                  'messages': [
                    {'role': 'system', 'content': 'You are a postpartum care specialist. Give empathetic, evidence-based advice.'},
                    {'role': 'user', 'content': 'Give 3 tips for postpartum recovery covering physical recovery, nutrition, and mental well-being.'},
                  ],
                }),
              );
              if (resp.statusCode == 200) {
                final data = jsonDecode(resp.body);
                if (mounted) setState(() => _aiAdvice = data['choices'][0]['message']['content'].toString().trim());
              }
            } catch (_) {} finally {
              if (mounted) setState(() => _aiLoading = false);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.pink.withAlpha(10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.pink.withAlpha(60)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.pink, size: 18),
                const SizedBox(width: 8),
                const Text('AI Postpartum Advice', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_aiLoading) ...[const Spacer(),
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink))],
              ]),
              const SizedBox(height: 10),
              Text(_aiAdvice, style: const TextStyle(fontSize: 13, height: 1.6)),
              if (!_aiLoading)
                const Padding(padding: EdgeInsets.only(top: 6),
                    child: Text('Tap to refresh', style: TextStyle(color: Colors.pink, fontSize: 11, fontWeight: FontWeight.bold))),
            ]),
          ),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  // ── BABY TRACKER ────────────────────────────────────────────────────────────
  Widget _buildBabyTracker() {
    final babyAge = _deliveryDate != null
        ? DateTime.now().difference(_deliveryDate!).inDays
        : 0;
    final babyWeeks = babyAge ~/ 7;
    final babyMonths = babyAge ~/ 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Baby age card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFB39DDB)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Text('👶', style: TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Baby is', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('$babyMonths months, ${babyAge % 30} days',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              Text('($babyWeeks weeks)', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Baby milestones
        _infoCard('🌱 Expected Milestones', [
          ..._babyMilestones(babyMonths),
        ], Colors.purple),
        const SizedBox(height: 16),

        // Log baby growth
        _infoCard('📏 Log Baby Growth', [
          _inputField(_babyWeightCtrl, 'Baby Weight (kg)', '3.5', Icons.scale_rounded),
          const SizedBox(height: 10),
          _inputField(_babyHeightCtrl, 'Baby Height (cm)', '50', Icons.height_rounded),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Baby Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveBabyLog,
            ),
          ),
        ], Colors.deepPurple),
        const SizedBox(height: 16),

        // Vaccination schedule
        _infoCard('💉 Vaccination Schedule', [
          _vaccineRow('BCG, Hep-B (1st dose)', 'At birth'),
          _vaccineRow('OPV-0, Hep-B (2nd dose)', '6 weeks'),
          _vaccineRow('DPT, Hib, PCV, Rota (1st)', '10 weeks'),
          _vaccineRow('DPT, Hib, PCV, Rota (2nd)', '14 weeks'),
          _vaccineRow('Measles, MMR (1st dose)', '9 months'),
          _vaccineRow('MMR (2nd dose)', '15 months'),
          _vaccineRow('DPT, OPV (Booster)', '16–24 months'),
        ], Colors.teal),
        const SizedBox(height: 16),

        // Baby log history
        if (_babyLogs.isNotEmpty) ...[
          const Text('📋 Growth History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ..._babyLogs.take(5).map((b) => _BabyLogTile(b)),
        ],
        const SizedBox(height: 80),
      ]),
    );
  }

  List<Widget> _babyMilestones(int monthsOld) {
    final all = [
      (1,  'Raises head while on tummy. Follows faces with eyes.'),
      (2,  'Smiles socially. Makes cooing sounds.'),
      (3,  'Holds head steady. Recognises parents. Laughs.'),
      (4,  'Rolls over (front to back). Reaches for objects.'),
      (6,  'Sits with support. Babbles. Recognises own name.'),
      (9,  'Crawls. Pulls to stand. Says "mama"/"dada".'),
      (12, 'Takes first steps. Uses simple words. Waves bye-bye.'),
      (18, 'Walks well. Says 10+ words. Points to body parts.'),
      (24, 'Runs. 50+ words. 2-word phrases. Parallel play.'),
    ];
    return all.map((m) {
      final done = monthsOld >= m.$1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: done ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.$1} month${m.$1 > 1 ? 's' : ''}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                      color: done ? Colors.green : Colors.grey)),
              Text(m.$2, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ]),
      );
    }).toList();
  }

  Widget _vaccineRow(String name, String schedule) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.vaccines_rounded, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
          Text(schedule, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      );

  Widget _checkItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          const Icon(Icons.check_box_rounded, color: Colors.pink, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );

  Widget _infoCard(String title, List<Widget> children, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _row(String label, String val) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );

  Widget _inputField(TextEditingController ctrl, String label, String hint, IconData icon,
      {TextInputType type = TextInputType.number}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.pink, size: 20),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _TrimChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  const _TrimChip(this.label, this.color, this.active);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(40) : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.grey.withAlpha(40)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? color : Colors.grey)),
      );
}

class _VitalLogTile extends StatelessWidget {
  final Map<String, dynamic> v;
  const _VitalLogTile(this.v);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.pink.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.monitor_heart_rounded, color: Colors.pink, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wk ${v['week'] ?? '?'}  •  ${v['weight_kg'] != null ? '${v['weight_kg']} kg' : ''}  ${v['blood_pressure'] != null ? '• BP ${v['blood_pressure']}' : ''}  ${v['kick_count'] != null ? '• ${v['kick_count']} kicks' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            (v['recorded_at'] as String? ?? '').split('T').first,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ]),
      );
}

class _BabyLogTile extends StatelessWidget {
  final Map<String, dynamic> b;
  const _BabyLogTile(this.b);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Text('👶', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${b['weight_kg'] != null ? '${b['weight_kg']} kg' : ''}  ${b['height_cm'] != null ? '• ${b['height_cm']} cm' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text((b['recorded_at'] as String? ?? '').split('T').first,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      );
}

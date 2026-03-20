import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_role.dart';

class MaternalDashboardScreen extends ConsumerWidget {
  const MaternalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isParent = user?.role == UserRole.parent;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maternal & Baby Care'),
          bottom: TabBar(
            indicatorColor: AppColors.accentPink,
            labelColor: AppColors.accentPink,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: const Icon(Icons.pregnant_woman_rounded), text: isParent ? 'Baby Care' : 'Pregnancy'),
              const Tab(icon: Icon(Icons.medical_services_outlined), text: 'Vitals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isParent ? const _BabyCareTab() : const _PregnancyTab(),
            const _VitalsTab(),
          ],
        ),
      ),
    );
  }
}

class _PregnancyTab extends StatelessWidget {
  const _PregnancyTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trimester card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentPink, AppColors.accentViolet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Week 24', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 4),
                Text('2nd Trimester', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Due Date: July 15, 2026', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nutrition Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _NutritionTip(title: 'Folic Acid', value: '400 mcg/day', icon: Icons.spa_rounded, color: AppColors.success),
          _NutritionTip(title: 'Iron', value: '27 mg/day', icon: Icons.bolt_rounded, color: AppColors.accentAmber),
          _NutritionTip(title: 'Calcium', value: '1000 mg/day', icon: Icons.grain_rounded, color: AppColors.info),
          const SizedBox(height: 20),
          const Text('Safe Ayurvedic Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _AyurvedicCard(name: 'Shatavari', benefit: 'Supports hormonal balance & lactation'),
          _AyurvedicCard(name: 'Ginger Tea', benefit: 'Helps with morning sickness'),
          _AyurvedicCard(name: 'Dates', benefit: 'Rich in iron and natural sugars'),
        ],
      ),
    );
  }
}

class _BabyCareTab extends StatelessWidget {
  const _BabyCareTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Feeding Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _FeedingEntry(time: '8:00 AM', type: 'Breast', duration: '15 min'),
          _FeedingEntry(time: '11:30 AM', type: 'Breast', duration: '12 min'),
          _FeedingEntry(time: '2:00 PM', type: 'Formula', duration: '90 ml'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log Feeding'),
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          const Text('Sleep Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          _SleepEntry(start: '7:30 PM', end: '4:30 AM', hours: '9h'),
          const SizedBox(height: 20),
          const Text('Growth Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _GrowthCard(label: 'Weight', value: '4.2 kg')),
              const SizedBox(width: 12),
              Expanded(child: _GrowthCard(label: 'Height', value: '54 cm')),
              const SizedBox(width: 12),
              Expanded(child: _GrowthCard(label: 'Head', value: '37 cm')),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalsTab extends StatelessWidget {
  const _VitalsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Blood Pressure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('120', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                  Text('Systolic (mmHg)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
                Text('/', style: TextStyle(fontSize: 32, color: Colors.grey)),
                Column(children: [
                  Text('80', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.accentViolet)),
                  Text('Diastolic (mmHg)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Heart Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentPink.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentPink.withAlpha(60)),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite_rounded, color: AppColors.accentPink, size: 36),
                SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('88 bpm', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Normal range for pregnancy', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTip extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _NutritionTip({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AyurvedicCard extends StatelessWidget {
  final String name, benefit;
  const _AyurvedicCard({required this.name, required this.benefit});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(benefit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class _FeedingEntry extends StatelessWidget {
  final String time, type, duration;
  const _FeedingEntry({required this.time, required this.type, required this.duration});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.accentViolet.withAlpha(30),
        child: const Icon(Icons.water_drop_rounded, color: AppColors.accentViolet, size: 18),
      ),
      title: Text('$type Feed — $duration'),
      subtitle: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}

class _SleepEntry extends StatelessWidget {
  final String start, end, hours;
  const _SleepEntry({required this.start, required this.end, required this.hours});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.accentViolet.withAlpha(30),
        child: const Icon(Icons.bedtime_rounded, color: AppColors.accentViolet, size: 18),
      ),
      title: Text('$hours • $start → $end'),
      subtitle: const Text('Night sleep', style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  final String label, value;
  const _GrowthCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryTeal)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class DoctorListScreen extends ConsumerWidget {
  const DoctorListScreen({super.key});

  static const _doctors = [
    {'name': 'Dr. Priya Sharma', 'specialty': 'Nutritionist', 'rating': 4.8, 'fee': 500},
    {'name': 'Dr. Arjun Mehta', 'specialty': 'Physiotherapist', 'rating': 4.6, 'fee': 400},
    {'name': 'Dr. Sunita Patel', 'specialty': 'Gynecologist', 'rating': 4.9, 'fee': 800},
    {'name': 'Dr. Rahul Verma', 'specialty': 'Mental Health Expert', 'rating': 4.7, 'fee': 600},
    {'name': 'Dr. Anita Gupta', 'specialty': 'General Physician', 'rating': 4.5, 'fee': 350},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _doctors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final doc = _doctors[i];
          return _DoctorCard(doctor: doc);
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryTeal.withAlpha(40),
            child: const Icon(Icons.person_rounded, color: AppColors.primaryTeal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(doctor['specialty'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accentAmber, size: 14),
                    const SizedBox(width: 2),
                    Text('${doctor['rating']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('₹${doctor['fee']}/session',
                        style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/payment', extra: {'doctor': doctor}),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}

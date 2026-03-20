import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class EmergencyAlertScreen extends StatelessWidget {
  const EmergencyAlertScreen({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.error.withAlpha(20),
      appBar: AppBar(
        title: const Text('Emergency Alert', style: TextStyle(color: AppColors.error)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.error),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 100, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'High Heart Rate Detected!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your BPM has exceeded the safe threshold. Please stay calm and take action if needed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            _EmergencyActionCard(
              icon: Icons.local_hospital_rounded,
              title: 'Call Emergency (102/108)',
              subtitle: 'Immediate medical assistance',
              color: AppColors.error,
              onTap: () => _makeCall('108'),
            ),
            const SizedBox(height: 16),
            _EmergencyActionCard(
              icon: Icons.contact_phone_rounded,
              title: 'Notify Emergency Contact',
              subtitle: 'Send alert to your primary contact',
              color: AppColors.warning,
              onTap: () {
                // In a real app, this would send an SMS or notification
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency contact notified!')),
                );
              },
            ),
            const SizedBox(height: 16),
            _EmergencyActionCard(
              icon: Icons.medical_services_rounded,
              title: 'Call Your Doctor',
              subtitle: 'Get advice from your professional',
              color: AppColors.info,
              onTap: () => _makeCall('9112345678'), // Placeholder
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('I am fine, dismiss alert', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

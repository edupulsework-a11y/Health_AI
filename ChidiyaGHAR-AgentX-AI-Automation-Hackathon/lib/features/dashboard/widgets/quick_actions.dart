import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          'Scan Food',
          Icons.camera_alt_outlined,
          AppColors.primary,
          () => Navigator.pushNamed(context, '/scan'),
        ),
        _buildActionCard(
          'Chat with AI',
          Icons.computer_rounded,
          AppColors.secondary,
          () => Navigator.pushNamed(context, '/ai-chat'),
        ),
        _buildActionCard(
          'Book Expert',
          Icons.calendar_month_outlined,
          AppColors.accent,
          () => Navigator.pushNamed(context, '/professionals'),
        ),
        _buildActionCard(
          'Analyze Report',
          Icons.analytics_outlined,
          Colors.deepPurple,
          () => Navigator.pushNamed(context, '/analyze-report'),
        ),
        _buildActionCard(
          'Demo Call',
          Icons.videocam_outlined,
          AppColors.error,
          () => Navigator.pushNamed(context, '/demo-call'),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

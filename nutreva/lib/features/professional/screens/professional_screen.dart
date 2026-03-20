import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../widgets/unified_consultation_modal.dart';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ProfessionalConnectScreen extends StatefulWidget {
  const ProfessionalConnectScreen({super.key});

  @override
  State<ProfessionalConnectScreen> createState() => _ProfessionalConnectScreenState();
}

class _ProfessionalConnectScreenState extends State<ProfessionalConnectScreen> {
  List<Map<String, dynamic>> _specialists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpecialists();
  }

  Future<void> _fetchSpecialists() async {
    try {
      final response = await supabase.Supabase.instance.client
          .from('user_data')
          .select()
          .eq('role', 'specialist')
          .limit(20);

      if (mounted) {
        setState(() {
          _specialists = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching specialists: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect with Experts')),
      body: RefreshIndicator(
        onRefresh: _fetchSpecialists,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
             _buildSessionHeader(context),
             const SizedBox(height: 24),
             const Text("Recommended Experts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             if (_isLoading)
                const Center(child: CircularProgressIndicator())
             else if (_specialists.isEmpty)
                const Center(child: Text('No experts found at the moment.'))
             else
                ..._specialists.map((s) => _buildExpertCard(
                  context, 
                  Expert(
                    name: s['name'] ?? 'Specialist', 
                    expertise: s['specialization'] ?? 'Health Consultant', 
                    rating: 4.8, 
                    image: (s['name'] ?? 'S')[0]
                  )
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, Expert expert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withAlpha(26),
                child: Text(expert.image, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expert.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(expert.expertise, style: const TextStyle(color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(expert.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.primary.withAlpha(128)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Session'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withAlpha(76), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const UnifiedConsultationModal(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Join Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSessionHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withAlpha(76), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.video_call_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                "Instant Meeting",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const UnifiedConsultationModal(),
                    );
                  },
                  icon: const Icon(Icons.videocam_rounded, color: AppColors.secondary),
                  label: const Text("Consult Now", style: TextStyle(color: AppColors.secondary)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class Expert {
  final String name;
  final String expertise;
  final double rating;
  final String image;
  const Expert({required this.name, required this.expertise, required this.rating, required this.image});
}

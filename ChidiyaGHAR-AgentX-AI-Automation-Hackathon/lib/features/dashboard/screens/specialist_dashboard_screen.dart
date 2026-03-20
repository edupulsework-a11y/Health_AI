import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme.dart';
import '../../../core/user_model.dart';
import '../../../services/stream_service.dart';
import '../../../services/auth_service.dart';

import '../../../services/pdf_service.dart';
import '../../../services/blockchain_service.dart';
import 'package:open_file/open_file.dart';
import '../../professional/screens/demo_call_screen.dart';
import '../../professional/widgets/unified_consultation_modal.dart';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SpecialistDashboardScreen extends StatefulWidget {
  final UserData specialist;
  const SpecialistDashboardScreen({super.key, required this.specialist});

  @override
  State<SpecialistDashboardScreen> createState() => _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends State<SpecialistDashboardScreen> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _foodLogs = [];
  bool _isLoading = true;
  UserData? _realSpecialist;
  double _totalEarnings = 1497.0; // Mock base + dynamic if possible
  int _communitySteps = 45200;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    await Future.wait([
      _fetchSpecialistProfile(),
      _fetchNewPatients(),
      _fetchRecentReports(),
      _fetchRecentFoodLogs(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchSpecialistProfile() async {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase.Supabase.instance.client
          .from('user_data')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _realSpecialist = UserData(
            name: data['full_name'] ?? data['name'] ?? 'Specialist',
            email: user.email ?? '',
            age: data['age'] ?? 35,
            category: data['category'] ?? 'Health Specialist',
            gender: data['gender'] ?? 'Male',
            accountType: AccountType.specialist,
            isAbhaVerified: true,
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching specialist profile: $e');
    }
  }

  Future<void> _fetchRecentReports() async {
    try {
      final response = await supabase.Supabase.instance.client
          .from('report_analysis')
          .select('*, user_data(name)')
          .order('created_at', ascending: false)
          .limit(5);
      
      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    }
  }

  Future<void> _fetchRecentFoodLogs() async {
    try {
      final response = await supabase.Supabase.instance.client
          .from('food_logs')
          .select('*, user_data(name)')
          .order('created_at', ascending: false)
          .limit(5);
      
      if (mounted) {
        setState(() {
          _foodLogs = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching food logs: $e');
    }
  }

  Future<void> _fetchNewPatients() async {
    try {
      final response = await supabase.Supabase.instance.client
          .from('user_data')
          .select()
          .eq('role', 'user')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _patients = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndOpenPlan(BuildContext context, String name, String type) async {
    // Simulated patient data for PDF
    final patient = UserData(
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
      age: type == 'Senior Citizen' ? 65 : 28,
      gender: 'Male',
      category: type,
      weight: 72,
      height: 175,
    );

    final exercises = type == 'Working Professional' 
      ? ['Cobra Stretch', 'Desk Neck Stretches', 'Lower Back Rotations']
      : ['Mountain Pose', 'Cat-Cow Stretch', 'Gentle Neck Rolls'];

    final file = await PdfService.generateHealthPlan(patient, 'Yoga', exercises);
    
    // Anchor to Blockchain
    final record = {
      'patient': name,
      'type': 'Health Plan',
      'timestamp': DateTime.now().toIso8601String(),
    };
    final recordHash = BlockchainService.generateRecordHash(record);
    final txHash = await BlockchainService.anchorToBlockchain(recordHash);

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan Anchored on Solana! Tx: ${txHash.substring(0, 10)}...'),
          action: SnackBarAction(label: 'View', onPressed: () {}),
        ),
      );
    }

    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialist Portal', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textLight)),
            Text(_realSpecialist?.name ?? widget.specialist.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          if (_realSpecialist?.isAbhaVerified ?? widget.specialist.isAbhaVerified)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                label: const Text('ABHA Verified', style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: AppColors.secondary,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNewPatients,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatGrid(context),
              const SizedBox(height: 24),
              _buildEarningsStepsCard(context),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Patients', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _fetchDashboardData, child: const Text('Refresh')),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_patients.isEmpty)
                const Center(child: Text('No new patients found.'))
              else
                ..._patients.map((p) => _buildConsultationCard(
                  context, 
                  p['name'] ?? 'User', 
                  p['category'] ?? 'General', 
                  'New Discovery', 
                  'Needs Consultation'
                )),
              const SizedBox(height: 32),
              Text('Health Shared reports', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_reports.isEmpty)
                _buildReportCard(context, 'Blood_Report_Rudraksh.pdf', 'Just now')
              else
                ..._reports.map((r) {
                  final patientName = r['user_data']?['name'] ?? 'User';
                  return _buildReportCard(context, 'Report: $patientName', 'Just now');
                }),
              const SizedBox(height: 32),
              Text('Patient Food Consumption', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_foodLogs.isEmpty)
                const Center(child: Text('No recent food logs.', style: TextStyle(color: AppColors.textLight)))
              else
                ..._foodLogs.map((f) => _buildFoodLogCard(context, f)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsStepsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text('₹${_totalEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: Colors.white24),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Community Steps', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(_communitySteps.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLogCard(BuildContext context, Map<String, dynamic> log) {
    final patientName = log['user_data']?['name'] ?? 'User';
    final calories = log['calories'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.restaurant_rounded, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Consumed $calories kcal', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatItem(context, 'Total Patients', '128', Icons.people_outline, Colors.blue),
        _buildStatItem(context, 'Pending Reports', '5', Icons.description_outlined, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $label...')));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context, String name, String type, String time, String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(name[0])),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('$type • $reason', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              Text(time, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _generateAndOpenPlan(context, name, type),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Generate PDF Plan', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSessionOptions(context),
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: const Text('Start/Join Call', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSessionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UnifiedConsultationModal(),
    );
  }


  Widget _buildReportCard(BuildContext context, String title, String time) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $title...')));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            Text(time, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

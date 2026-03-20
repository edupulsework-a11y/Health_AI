import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../consultation/presentation/screens/consultation_modal.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _mealLogs = [];
  List<Map<String, dynamic>> _medicalReports = [];
  bool _loading = true;
  Map<String, dynamic>? _selectedPatient;

  @override
  void initState() {
    super.initState();
    _fetchAllPatients();
  }

  Future<void> _fetchAllPatients() async {
    setState(() => _loading = true);
    try {
      // Fetch all non-professional users
      final patients = await _supabase
          .from('profiles')
          .select()
          .neq('role', 'professional')
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _patients = List<Map<String, dynamic>>.from(patients);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPatientData(Map<String, dynamic> patient) async {
    setState(() { _selectedPatient = patient; _mealLogs = []; _medicalReports = []; });
    final uid = patient['id'] as String?;
    if (uid == null) return;

    try {
      final meals = await _supabase
          .from('meal_logs')
          .select()
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(10);

      final reports = await _supabase
          .from('medical_reports')
          .select()
          .eq('user_id', uid)
          .order('uploaded_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _mealLogs = List<Map<String, dynamic>>.from(meals);
          _medicalReports = List<Map<String, dynamic>>.from(reports);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(currentUserProvider);
    final doctorName = doctor?.name ?? 'Doctor';

    return Scaffold(
      body: Row(
        children: [
          // ── Patient List Panel ────────────────────
          Container(
            width: _selectedPatient == null ? double.infinity : 260,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(right: BorderSide(color: Colors.grey.withAlpha(30))),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A1628), AppColors.accentViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryTeal.withAlpha(60),
                            child: Text(doctorName.isNotEmpty ? doctorName[0] : 'D',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dr. $doctorName',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Text('Professional Panel',
                                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text('${_patients.length} Patients',
                                style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _fetchAllPatients,
                              child: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Patient List
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _patients.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No patients registered yet.',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _patients.length,
                              itemBuilder: (_, i) {
                                final p = _patients[i];
                                final isSelected = _selectedPatient?['id'] == p['id'];
                                final name = p['name'] ?? 'Unknown';
                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: AppColors.primaryTeal.withAlpha(20),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.primaryTeal.withAlpha(40)
                                        : Colors.grey.withAlpha(30),
                                    child: Text(name[0].toUpperCase(),
                                        style: TextStyle(
                                            color: isSelected
                                                ? AppColors.primaryTeal
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? AppColors.primaryTeal : null,
                                          fontSize: 13)),
                                  subtitle: Text(p['role'] ?? 'user',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  onTap: () => _loadPatientData(p),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // ── Patient Detail Panel ──────────────────
          if (_selectedPatient != null)
            Expanded(
              child: _PatientDetailPanel(
                patient: _selectedPatient!,
                mealLogs: _mealLogs,
                medicalReports: _medicalReports,
                onClose: () => setState(() => _selectedPatient = null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Patient Detail Panel ──────────────────────────────
class _PatientDetailPanel extends StatelessWidget {
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> mealLogs;
  final List<Map<String, dynamic>> medicalReports;
  final VoidCallback onClose;

  const _PatientDetailPanel({
    required this.patient,
    required this.mealLogs,
    required this.medicalReports,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] ?? 'Unknown';
    final email = patient['email'] ?? '';
    final role = patient['role'] ?? 'regular';
    final walletAddr = patient['wallet_address'] ?? '';
    final abhaVerified = patient['abha_verified'] == true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Patient: $name', style: const TextStyle(fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: onClose),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call_rounded, color: AppColors.primaryTeal),
            tooltip: 'Start consultation call',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _InfoCard(
              title: 'Patient Profile',
              icon: Icons.person_rounded,
              children: [
                _InfoRow('Name', name),
                _InfoRow('Email', email),
                _InfoRow('Role', role),
                _InfoRow('ABHA Verified', abhaVerified ? '✅ Yes' : '❌ No'),
                if (walletAddr.isNotEmpty)
                  _InfoRow('Wallet',
                      '${walletAddr.substring(0, 8)}...${walletAddr.substring(walletAddr.length - 6)}'),
              ],
            ),
            const SizedBox(height: 16),

            // Meal Logs
            _InfoCard(
              title: 'Recent Meal Logs',
              icon: Icons.restaurant_rounded,
              children: mealLogs.isEmpty
                  ? [const Text('No meal logs found.', style: TextStyle(color: Colors.grey))]
                  : mealLogs.map((m) => _MealLogTile(log: m)).toList(),
            ),
            const SizedBox(height: 16),

            // Medical Reports
            _InfoCard(
              title: 'Medical Reports',
              icon: Icons.medical_information_rounded,
              children: medicalReports.isEmpty
                  ? [const Text('No reports uploaded.', style: TextStyle(color: Colors.grey))]
                  : medicalReports.map((r) => _ReportTile(report: r)).toList(),
            ),
            const SizedBox(height: 16),

            // Consultation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('Start Consultation Call',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const UnifiedConsultationModal(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable small widgets ─────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primaryTeal, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}

class _MealLogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _MealLogTile({required this.log});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.fastfood_rounded, color: AppColors.primaryTeal, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(log['meal_name'] ?? 'Meal', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${log['calories'] ?? 0} kcal  ·  Protein: ${log['protein_g'] ?? 0}g',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
          Text('Bloating: ${log['bloating'] ?? 0}/5',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      );
}

class _ReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.picture_as_pdf_rounded, color: AppColors.info, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(report['ai_summary'] ?? 'Medical Report',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(report['next_step'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );
}

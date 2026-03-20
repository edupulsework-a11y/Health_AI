import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../blockchain/data/services/web3_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  int _steps = 0;
  double _heartRate = 0;
  double _sleepHours = 0;
  double _calories = 0;
  double _walletBal = 0;
  List<Map<String, dynamic>> _specialists = [];
  bool _loadingSpecialists = true;
  Timer? _vitalsTimer;

  @override
  void initState() {
    super.initState();
    _fetchSpecialists();
    _fetchWalletBalance();
    // Simulate vitals update every 10s (replace with real health package)
    _vitalsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          _steps += 12;
          _heartRate = 68 + (DateTime.now().second % 10);
          _sleepHours = 7.2;
          _calories += 2;
        });
      }
    });
    // Initial values
    setState(() {
      _steps = 4231;
      _heartRate = 72;
      _sleepHours = 7.2;
      _calories = 1340;
    });
  }

  @override
  void dispose() {
    _vitalsTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSpecialists() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'professional')
          .limit(6);
      if (mounted) setState(() { _specialists = List<Map<String, dynamic>>.from(data); _loadingSpecialists = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSpecialists = false);
    }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final addr = await ref.read(web3ServiceProvider).getStoredAddress();
      if (addr != null) {
        final bal = await ref.read(web3ServiceProvider).getBalance(addr);
        if (mounted) setState(() => _walletBal = bal);
      }
    } catch (_) {}
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = user?.name ?? 'User';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async { await _fetchSpecialists(); await _fetchWalletBalance(); },
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_greeting 👋',
                                style: const TextStyle(color: Colors.white60, fontSize: 14)),
                            Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryTeal.withAlpha(60),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Wallet mini card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text('${_walletBal.toStringAsFixed(4)} ETH',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          const Text('MegaETH Testnet',
                              style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Vitals Row ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _VitalCard(icon: Icons.directions_walk_rounded, label: 'Steps',
                        value: _steps.toString(), color: AppColors.primaryTeal),
                    _VitalCard(icon: Icons.favorite_rounded, label: 'BPM',
                        value: _heartRate.toInt().toString(), color: AppColors.error),
                    _VitalCard(icon: Icons.bedtime_rounded, label: 'Sleep',
                        value: '${_sleepHours}h', color: AppColors.accentViolet),
                    _VitalCard(icon: Icons.local_fire_department_rounded, label: 'kcal',
                        value: _calories.toInt().toString(), color: AppColors.warning),
                  ],
                ),
              ),
            ),

            // ── Quick Actions ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _QuickAction(icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan Food', color: AppColors.primaryTeal,
                            onTap: () {}),
                        _QuickAction(icon: Icons.restaurant_menu_rounded,
                            label: 'Meal Log', color: AppColors.success,
                            onTap: () {}),
                        _QuickAction(icon: Icons.analytics_rounded,
                            label: 'Medical AI', color: AppColors.info,
                            onTap: () {}),
                        _QuickAction(icon: Icons.video_call_rounded,
                            label: 'Consult', color: AppColors.accentViolet,
                            onTap: () {}),
                        _QuickAction(icon: Icons.pregnant_woman_rounded,
                            label: 'Maternal', color: Colors.pink,
                            onTap: () {}),
                        _QuickAction(icon: Icons.sensors_rounded,
                            label: 'IoT Live', color: Colors.orange,
                            onTap: () {}),
                        _QuickAction(icon: Icons.account_balance_wallet_rounded,
                            label: 'Wallet', color: AppColors.warning,
                            onTap: () {}),
                        _QuickAction(icon: Icons.emergency_rounded,
                            label: 'Emergency', color: AppColors.error,
                            onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Goals ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today\'s Goals',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 14),
                    _GoalBar(label: 'Steps', value: _steps / 10000,
                        subtitle: '$_steps / 10,000', color: AppColors.primaryTeal),
                    const SizedBox(height: 10),
                    _GoalBar(label: 'Calories', value: _calories / 2000,
                        subtitle: '${_calories.toInt()} / 2000 kcal', color: AppColors.warning),
                    const SizedBox(height: 10),
                    _GoalBar(label: 'Hydration', value: 0.6,
                        subtitle: '1.5 / 2.5 L', color: AppColors.info),
                  ],
                ),
              ),
            ),

            // ── Specialists Online ────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Specialists Online',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 14),
                    _loadingSpecialists
                        ? const LinearProgressIndicator()
                        : _specialists.isEmpty
                            ? const Text('No specialists online right now.',
                                style: TextStyle(color: Colors.grey))
                            : SizedBox(
                                height: 110,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _specialists.length,
                                  itemBuilder: (_, i) {
                                    final s = _specialists[i];
                                    final n = s['name'] ?? 'Doctor';
                                    return Container(
                                      width: 90,
                                      margin: const EdgeInsets.only(right: 14),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 32,
                                            backgroundColor: AppColors.primaryTeal.withAlpha(30),
                                            child: Text(n[0],
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryTeal)),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(n,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                          Text(s['specialization'] ?? 'Expert',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _VitalCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      );
}

class _GoalBar extends StatelessWidget {
  final String label, subtitle;
  final double value;
  final Color color;
  const _GoalBar({required this.label, required this.subtitle, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${(value.clamp(0, 1) * 100).toInt()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 8,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        ],
      );
}

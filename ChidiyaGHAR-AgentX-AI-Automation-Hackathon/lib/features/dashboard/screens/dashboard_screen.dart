import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/user_model.dart';
import '../widgets/nutrition_rings.dart';
import '../widgets/quick_actions.dart';
import '../../nutrition/screens/food_scan_screen.dart';
import '../../../services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../professional/screens/demo_call_screen.dart';
import '../../wellness/screens/senior_wellness_screen.dart';
import '../../professional/widgets/unified_consultation_modal.dart';

class DashboardScreen extends StatefulWidget {
  final UserData user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _hydrationTimer;
  final HealthService _healthService = HealthService();
  UserData? _currentUser;

  @override
  void initState() {
    super.initState();
    // Sync User Data & Calculate Goals
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
      _healthService.fetchTodayLogs();
      _fetchSpecialists(); // ADDED: Discover specialists on startup
    });

    _healthService.addListener(_onHealthUpdate);
    
    // Vitals Simulation (Real-time feel)
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
         // Simulate steps only if user is Active
         if (widget.user.activityLevel == 'Active' || widget.user.activityLevel == 'Very Active') {
            _healthService.addSteps(5);
         } else {
             _healthService.addSteps(1);
         }
      }
    });

    _hydrationTimer = Timer.periodic(const Duration(minutes: 60), (timer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Time to drink water! Keep your hydration goal on track. 💧'), backgroundColor: Colors.cyan),
        );
      }
    });
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('user_data')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        final profile = UserData(
          name: data['full_name'] ?? data['name'] ?? 'User',
          email: user.email ?? '',
          phone: data['phone'],
          age: data['age'] ?? 25,
          weight: (data['weight'] as num?)?.toDouble(),
          height: (data['height'] as num?)?.toDouble(),
          gender: data['gender'] ?? 'Male',
          category: data['category'] ?? 'Working Professional',
          activityLevel: data['activity_level'],
          dietaryPreference: data['dietary_preference'],
          accountType: data['account_type'] == 'specialist' ? AccountType.specialist : AccountType.user,
        );

        setState(() {
          _currentUser = profile;
        });

        _healthService.updateProfile(
          name: profile.name,
          email: profile.email,
          phone: profile.phone,
          height: profile.height,
          weight: profile.weight,
        );
        
        // Re-calculate goals with real data
        _calculateAndSetGoalsWithData(profile);
      } else {
        // Fallback to widget user if DB fetch fails
        _healthService.updateProfile(
          name: widget.user.name,
          email: widget.user.email,
          phone: widget.user.phone,
          height: widget.user.height,
          weight: widget.user.weight,
        );
        _calculateAndSetGoals();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  void _calculateAndSetGoalsWithData(UserData u) {
    double bmr;
    if (u.isFemale) {
       bmr = (10 * (u.weight ?? 60)) + (6.25 * (u.height ?? 160)) - (5 * u.age) - 161;
    } else {
       bmr = (10 * (u.weight ?? 70)) + (6.25 * (u.height ?? 170)) - (5 * u.age) + 5;
    }

    double activityFactor = 1.2;
    switch (u.activityLevel) {
       case 'Sedentary': activityFactor = 1.2; break;
       case 'Light': activityFactor = 1.375; break;
       case 'Moderate': activityFactor = 1.55; break;
       case 'Active': activityFactor = 1.725; break;
       case 'Very Active': activityFactor = 1.9; break;
    }

    final double tdee = bmr * activityFactor;
    final double protein = (tdee * 0.20) / 4;
    final double fats = (tdee * 0.30) / 9;
    final double carbs = (tdee * 0.50) / 4;
    final double water = (u.weight ?? 60) * 0.033;

    _healthService.updateGoals(
       calorieGoal: tdee,
       proteinGoal: protein,
       fatsGoal: fats,
       carbsGoal: carbs,
       waterGoal: water < 2.0 ? 2.0 : water,
       stepGoal: u.activityLevel == 'Sedentary' ? 5000 : 10000,
    );
  }

  void _calculateAndSetGoals() {
    final u = widget.user;
    double bmr;
    
    // Mifflin-St Jeor Equation
    if (u.isFemale) {
       bmr = (10 * (u.weight ?? 60)) + (6.25 * (u.height ?? 160)) - (5 * u.age) - 161;
    } else {
       bmr = (10 * (u.weight ?? 70)) + (6.25 * (u.height ?? 170)) - (5 * u.age) + 5;
    }

    double activityFactor = 1.2;
    switch (u.activityLevel) {
       case 'Sedentary': activityFactor = 1.2; break;
       case 'Light': activityFactor = 1.375; break;
       case 'Moderate': activityFactor = 1.55; break;
       case 'Active': activityFactor = 1.725; break;
       case 'Very Active': activityFactor = 1.9; break;
    }

    final double tdee = bmr * activityFactor;
    
    // Simple Macro Split (50% Carbs, 30% Fat, 20% Protein)
    final double protein = (tdee * 0.20) / 4;
    final double fats = (tdee * 0.30) / 9;
    final double carbs = (tdee * 0.50) / 4;
    
    final double water = (u.weight ?? 60) * 0.033; // 33ml per kg

    _healthService.updateGoals(
       calorieGoal: tdee,
       proteinGoal: protein,
       fatsGoal: fats,
       carbsGoal: carbs,
       waterGoal: water < 2.0 ? 2.0 : water, // Min 2L
       stepGoal: u.activityLevel == 'Sedentary' ? 5000 : 10000,
    );
  }

  @override
  void dispose() {
    _healthService.removeListener(_onHealthUpdate);
    _hydrationTimer?.cancel();
    super.dispose();
  }

  void _onHealthUpdate() {
    if (mounted) setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingPhrase(UserData user) {
    if (user.category == 'Teenager') return 'Stay active,';
    if (user.category == 'Senior Citizen') return 'Take it easy,';
    return '${_getGreeting()},';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Header Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/dashboard_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withOpacity(0.8),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreetingPhrase(widget.user),
                            style: const TextStyle(color: AppColors.textLight, fontSize: 16),
                          ),
                          Text(
                            _healthService.currentData.userName,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const NutritionRings(),
                  const SizedBox(height: 32),
                  const Text(
                    'Health Hub',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const QuickActionsGrid(),
                  const SizedBox(height: 32),
                  _buildActiveGoals(),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),
                  _buildVideoConsultationCard(context),
                  const SizedBox(height: 32),
                  const Text('Specialists Online', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildSpecialistCarousel(),
                  const SizedBox(height: 24),
                  _buildSeniorWellnessCard(context), // New Feature
                  const SizedBox(height: 24),
                  _buildHealthTip(context, _currentUser ?? widget.user),
                  if ((_currentUser ?? widget.user).isFemale) ...[
                    const SizedBox(height: 24),
                    _buildMenstrualPreview(context),
                  ],
                  const SizedBox(height: 80), // Extra space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/scan');
          if (index == 2) Navigator.pushNamed(context, '/ai-chat');
          if (index == 3) Navigator.pushNamed(context, '/professionals');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Experts'),
        ],
      ),
    );
  }

  Widget _buildActiveGoals() {
    final data = _healthService.currentData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Goals',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            children: [
              _buildGoalItem('Hydration', 'Drink ${data.waterGoal}L of water', data.water / data.waterGoal, Colors.cyan),
              const SizedBox(height: 16),
              _buildGoalItem('Activity', '${data.stepGoal} steps daily', data.steps / data.stepGoal, Colors.blue),
              const SizedBox(height: 16),
              _buildGoalItem('Protein', '${data.proteinGoal.toInt()}g daily intake', data.protein / data.proteinGoal, AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(String title, String subtitle, double progress, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
            Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(10),
          minHeight: 10,
        ),
      ],
    );
  }

  Widget _buildHealthTip(BuildContext context, UserData user) {
    String title = "Daily Wellness";
    String tip = "Stay hydrated and keep moving!";
    
    if (user.category == 'Working Professional') {
      title = "Office Wellness";
      tip = "Take a 5-min walk every 90 mins to improve circulation.";
    } else if (user.category == 'Senior Citizen') {
      title = "Gentle Care";
      tip = "Morning sunlight for 15 mins helps with Vitamin D and sleep.";
    } else if (user.category == 'Teenager') {
      title = "Growth Tip";
      tip = "Consistent 8-hour sleep is vital for hormone regulation and growth.";
    } else if (user.category == 'Housewife') {
      title = "Home Health";
      tip = "Small intervals of yoga can help manage daily household stress.";
    }

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/ai-chat'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(tip, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenstrualPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: Colors.pink),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cycle Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                Text('Your next cycle starts in 4 days. Stay prepared!', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/menstrual'),
            child: const Text('Track', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoConsultationCard(BuildContext context) {
    return InkWell(
      onTap: () => _showSessionOptions(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: AppColors.secondary, size: 28),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Video Consultation', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  Text('Connect with your specialist instantly.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSeniorWellnessCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SeniorWellnessScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)], // Gold/Cream Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
             Positioned(
               right: -20,
               bottom: -20,
               child: Icon(Icons.spa_rounded, size: 120, color: Colors.orange.withOpacity(0.1)),
             ),
             Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(20)),
                     child: const Text("Premium", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(height: 8),
                   Text("Senior Citizen Wellness", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
                   const SizedBox(height: 4),
                   const Text("Ayurveda • Mobility • AI Vaidya", style: TextStyle(color: Color(0xFF5D4037), fontSize: 12)),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _specialists = [];

  Future<void> _fetchSpecialists() async {
    try {
      final response = await Supabase.instance.client
          .from('user_data')
          .select()
          .eq('role', 'specialist')
          .limit(5);

      if (mounted) {
        setState(() {
          _specialists = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching specialists for dashboard: $e');
    }
  }

  Widget _buildSpecialistCarousel() {
    if (_specialists.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('Searching for specialists...', style: TextStyle(color: AppColors.textLight)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialists.length,
        itemBuilder: (context, index) {
          final s = _specialists[index];
          final name = s['name'] ?? 'Specialist';
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  s['specialization'] ?? 'Expert',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                ),
              ],
            ),
          );
        },
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

}

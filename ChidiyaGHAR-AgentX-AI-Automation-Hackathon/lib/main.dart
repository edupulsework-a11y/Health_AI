import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/nutrition/screens/food_scan_screen.dart';
import 'features/nutrition/screens/report_analysis_screen.dart';
import 'features/ai_chat/screens/ai_chat_screen.dart';
import 'features/menstrual/screens/menstrual_screen.dart';
import 'features/professional/screens/professional_screen.dart';
import 'features/professional/screens/demo_call_screen.dart';
import 'features/auth/screens/post_signup_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/dashboard/screens/specialist_dashboard_screen.dart';
import 'features/auth/screens/permission_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/signup_details_screen.dart';
import 'core/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/api_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaAI Health',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(builder: (context) => DashboardScreen(user: mockUser));
        }
        if (settings.name == '/specialist-dashboard') {
          return MaterialPageRoute(builder: (context) => SpecialistDashboardScreen(specialist: mockSpecialist));
        }
        if (settings.name == '/post-signup') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => PostSignupScreen(isSpecialist: args['isSpecialist'] ?? false),
          );
        }
        if (settings.name == '/permissions') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => PermissionScreen(isSpecialist: args['isSpecialist'] ?? false),
          );
        }
        if (settings.name == '/signup-details') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
             builder: (context) => SignupDetailsScreen(isSpecialist: args['isSpecialist'] ?? false),
          );
        }
        if (settings.name == '/role-selection') {
          return MaterialPageRoute(builder: (context) => const RoleSelectionScreen());
        }
        return null;
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/scan': (context) => const FoodScanScreen(),
        '/ai-chat': (context) => const AIChatScreen(),
        '/analyze-report': (context) => const ReportAnalysisScreen(),
        '/menstrual': (context) => const MenstrualModule(),
        '/professionals': (context) => const ProfessionalConnectScreen(),
        '/demo-call': (context) => const DemoCallScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

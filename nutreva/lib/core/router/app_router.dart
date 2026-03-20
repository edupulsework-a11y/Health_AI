import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/abha_verification_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/food/presentation/screens/food_tab_screen.dart';
import '../../features/meal_logging/presentation/screens/meal_log_screen.dart';
import '../../features/maternal/presentation/screens/maternal_dashboard_screen.dart';
import '../../features/medical_ai/presentation/screens/medical_ai_screen.dart';
import '../../features/consultation/presentation/screens/doctor_list_screen.dart';
import '../../features/consultation/presentation/screens/payment_screen.dart';
import '../../features/blockchain/presentation/screens/wallet_screen.dart';
import '../../features/emergency/presentation/screens/emergency_alert_screen.dart';
import '../../features/doctor_panel/presentation/screens/doctor_dashboard_screen.dart';
import '../../shared/widgets/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState is AuthAuthenticated;
      final isAuthRoute = state.uri.toString().startsWith('/login') ||
          state.uri.toString().startsWith('/signup');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/role-selection',
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/abha-verification',
        builder: (_, __) => const AbhaVerificationScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/food',
            builder: (_, __) => const FoodTabScreen(),
          ),
          GoRoute(
            path: '/maternal',
            builder: (_, __) => const MaternalDashboardScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, __) => const WalletScreen(),
          ),
          GoRoute(
            path: '/consultations',
            builder: (_, __) => const DoctorListScreen(),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: '/meal-log',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MealLogScreen(initialData: extra);
        },
      ),
      GoRoute(
        path: '/medical-ai',
        builder: (_, __) => const MedicalAIScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentScreen(extra: extra);
        },
      ),
      GoRoute(
        path: '/emergency',
        builder: (_, __) => const EmergencyAlertScreen(),
      ),
      GoRoute(
        path: '/doctor-panel',
        builder: (_, __) => const DoctorDashboardScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});

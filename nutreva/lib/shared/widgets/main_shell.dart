import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/dashboard', icon: Icons.home_rounded, label: 'Home'),
    (path: '/food', icon: Icons.restaurant_rounded, label: 'Food'),
    (path: '/consultations', icon: Icons.video_call_rounded, label: 'Consult'),
    (path: '/maternal', icon: Icons.favorite_rounded, label: 'Care'),
    (path: '/wallet', icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final user = ref.watch(currentUserProvider);
    final currentIndex = _tabs.indexWhere(
      (t) => location.startsWith(t.path),
    ).clamp(0, _tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
      floatingActionButton: user?.role == UserRole.professional
          ? FloatingActionButton.small(
              onPressed: () => context.go('/doctor-panel'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.medical_information_rounded),
            )
          : null,
    );
  }
}

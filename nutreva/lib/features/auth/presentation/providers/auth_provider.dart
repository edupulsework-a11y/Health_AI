import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';

// ── Auth State ────────────────────────────────────────
sealed class AuthState {}
class AuthInitial      extends AuthState {}
class AuthLoading      extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ── Auth Notifier (Riverpod v3 → Notifier) ────────────
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _auth;

  @override
  AuthState build() {
    _auth = ref.read(authServiceProvider);
    // Check session on first build
    _checkCurrentUser();
    return AuthInitial();
  }

  void _checkCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _loadProfile();
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<void> _loadProfile() async {
    try {
      state = AuthLoading();
      final user = await _auth.getCurrentUserProfile();
      state = AuthAuthenticated(user);
    } catch (_) {
      state = AuthUnauthenticated();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AuthLoading();
    try {
      final user = await _auth.signInWithEmail(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = AuthLoading();
    try {
      final user = await _auth.signUpWithEmail(
        email: email, password: password, name: name, role: role);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final user = await _auth.signInWithGoogle();
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = AuthUnauthenticated();
  }

  Future<void> verifyABHA(String abhaId) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    final success = await _auth.verifyABHA(abhaId);
    if (success) {
      state = AuthAuthenticated(current.user.copyWith(abhaVerified: true));
    }
  }
}

// ── Providers ──────────────────────────────────────────
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) {
  final auth = ref.watch(authNotifierProvider);
  if (auth is AuthAuthenticated) return auth.user;
  return null;
});

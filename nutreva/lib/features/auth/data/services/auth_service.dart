import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';
import '../../../blockchain/data/services/web3_service.dart';
import '../../../../core/constants/app_constants.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

class AuthService {
  final Ref _ref;
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleClientId,
  );

  AuthService(this._ref);

  // ── Email Sign Up ─────────────────────────────
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role.name},
    );
    final uid = response.user?.id ?? '';

    // Generate wallet via backend
    final walletAddress = await _generateWallet(uid);

    // Upsert profile row
    await _supabase.from('profiles').upsert({
      'id': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'wallet_address': walletAddress,
      'abha_verified': false,
    });

    return UserModel(
      id: uid,
      email: email,
      name: name,
      role: role,
      walletAddress: walletAddress,
    );
  }

  // ── Email Sign In ─────────────────────────────
  Future<UserModel> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
    return _fetchProfile();
  }

  // ── Google Sign In ────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final auth = await googleUser.authentication;
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: auth.idToken!,
      accessToken: auth.accessToken,
    );
    return _fetchProfile();
  }

  // ── Sign Out ──────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  // ── ABHA Verification ─────────────────────────
  Future<bool> verifyABHA(String abhaId) async {
    // TODO: call ABDM ABHA verification API
    // Placeholder: upsert on success
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;
    await _supabase.from('profiles').update({'abha_verified': true}).eq('id', uid);
    return true;
  }

  // ── Internal Helpers ──────────────────────────
  Future<UserModel> _fetchProfile() async {
    final uid = _supabase.auth.currentUser?.id ?? '';
    final data = await _supabase.from('profiles').select().eq('id', uid).single();
    return UserModel.fromJson(data);
  }

  Future<String> _generateWallet(String userId) async {
    try {
      return _ref.read(web3ServiceProvider).createWallet();
    } catch (_) {
      return '0x0000000000000000000000000000000000000000';
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  /// Public alias for auth_provider — fetches Supabase profile for current session
  Future<UserModel> getCurrentUserProfile() => _fetchProfile();
}

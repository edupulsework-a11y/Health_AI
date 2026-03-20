import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Ensure you've configured the correct scopes/client IDs if needed
    // For Android, usually the google-services.json flow handles SHA-1, 
    // but here we just need the tokens to pass to Supabase.
  );

  // Google Sign In -> Supabase
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // 1. Trigger the native Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // User cancelled

      // 2. Obtain the auth details (idToken and accessToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Sign in to Supabase with the tokens
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      return response;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('ApiException: 7')) {
        throw 'Network error. Please check your internet connection and try again.';
      }
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}

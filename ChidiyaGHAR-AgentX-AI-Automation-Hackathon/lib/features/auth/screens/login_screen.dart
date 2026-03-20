import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  // Toggle state: false = User, true = Specialist
  bool _isSpecialist = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Google Sign In
      final response = await _authService.signInWithGoogle();
      
      if (response != null && response.user != null) {
        // 2. Check if user exists in Supabase
        final user = response.user!;
        final data = await Supabase.instance.client
            .from('user_data')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          // User exists, redirect based on their stored role
          final role = data['account_type']; // 'user' or 'specialist'
          
          if (mounted) {
            if (role == 'specialist') {
               Navigator.pushNamedAndRemoveUntil(context, '/specialist-dashboard', (route) => false);
            } else {
               Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
            }
          }
        } else {
          // User not found in DB? Redirect to Role Selection for Signup
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account not found. Redirecting to Signup...')),
            );
             Navigator.pushNamed(context, '/role-selection');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton( // Added back button just in case
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(
                        child: Hero(
                          tag: 'logo',
                          child: Image.asset('assets/logo.jpeg', width: 120, height: 120),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Sign in to continue your health journey',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 48),
                      
                      // Role Toggle
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildToggleOption('User', !_isSpecialist, (val) => setState(() => _isSpecialist = !val)),
                              _buildToggleOption('Specialist', _isSpecialist, (val) => setState(() => _isSpecialist = val)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
        
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: BorderSide(color: Colors.grey[200]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Continue with Google', 
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account?'),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/role-selection'),
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper for Toggle (using _isSpecialist as boolean)
  Widget _buildToggleOption(String label, bool isSelected, Function(bool) onTap) {
    return GestureDetector(
      onTap: () => onTap(label == 'Specialist'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }
  
  // Helper getter for cleaner toggle logic
  bool get _ => _isSpecialist;
}

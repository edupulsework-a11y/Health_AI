import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';

class SignupDetailsScreen extends StatefulWidget {
  final bool isSpecialist;
  const SignupDetailsScreen({super.key, required this.isSpecialist});

  @override
  State<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends State<SignupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'Male';
  String _category = 'Working Professional';
  String _dietaryPreference = 'Vegetarian';
  String _activityLevel = 'Moderate';
  String _specialization = 'Nutritionist'; // For Specialists
  
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleGoogleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Perform Google Sign In
      final response = await _authService.signInWithGoogle();
      
      if (response != null && response.user != null) {
        final user = response.user!;
        
        // 2. Prepare Profile Data
        final profileData = {
          'id': user.id, // Supabase ID
          'email': user.email,
          'name': _nameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'gender': _gender,
          'category': _category,
          'height': double.tryParse(_heightController.text) ?? 0.0,
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'dietary_preference': _dietaryPreference,
          'activity_level': _activityLevel,
          'role': widget.isSpecialist ? 'specialist' : 'user',
          'specialization': widget.isSpecialist ? _specialization : null,
          'created_at': DateTime.now().toIso8601String(),
        };

        // 3. Save to Database (Supabase)
        // Check if user already exists to avoid overwriting or duplicate key errors if using upsert blindly without care, 
        // but here we are "signing up", so upsert is generally safe for profile creation.
        await Supabase.instance.client.from('user_data').upsert(profileData);

        // 4. Navigate to correct Dashboard
        if (mounted) {
           if (widget.isSpecialist) {
             Navigator.pushNamedAndRemoveUntil(context, '/specialist-dashboard', (route) => false);
           } else {
             Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSpecialist ? 'Specialist Details' : 'Your Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us a bit about yourself',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We need this to personalize your experience.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 32),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Age
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Gender
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded)),
                  items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _gender = val!),
                ),
                const SizedBox(height: 16),

                // Height & WeightRow
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_rounded)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dietary Preference
                DropdownButtonFormField<String>(
                  value: _dietaryPreference,
                  decoration: const InputDecoration(labelText: 'Dietary Preference', prefixIcon: Icon(Icons.restaurant_menu_rounded)),
                  items: ['Vegetarian', 'Eggetarian', 'Non-Vegetarian', 'Vegan', 'Jain']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _dietaryPreference = val!),
                ),
                const SizedBox(height: 16),

                // Activity Level
                DropdownButtonFormField<String>(
                  value: _activityLevel,
                  decoration: const InputDecoration(labelText: 'Activity Level', prefixIcon: Icon(Icons.directions_run_rounded)),
                  items: ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _activityLevel = val!),
                ),
                const SizedBox(height: 16),

                // Category (User) or Specialization (Specialist)
                if (widget.isSpecialist) 
                  DropdownButtonFormField<String>(
                    value: _specialization,
                    decoration: const InputDecoration(labelText: 'Specialization'),
                     items: ['Nutritionist', 'Physiotherapist', 'Yoga Instructor', 'Psychologist']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _specialization = val!),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                     items: ['Student', 'Working Professional', 'Housewife', 'Senior Native']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                
                const SizedBox(height: 48),

                // Google Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
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
                const SizedBox(height: 16),
                Center(
                   child: Text(
                    'By continuing, you agree to our Terms & Conditions.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                   ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostSignupScreen extends StatefulWidget {
  final bool isSpecialist;
  const PostSignupScreen({super.key, this.isSpecialist = false});

  @override
  State<PostSignupScreen> createState() => _PostSignupScreenState();
}

class _PostSignupScreenState extends State<PostSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _gender = 'Male';
  String _category = 'Working Professional';
  String _specialization = 'Physiotherapist';
  bool _isSpecialistAccount = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _idController = TextEditingController();
  final _certController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSpecialistAccount = widget.isSpecialist;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? "";
      _nameController.text = user.userMetadata?['full_name'] ?? "";
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'No user found';

      final profileData = {
        'id': user.id,
        'name': _nameController.text,
        'email': user.email,
        'phone': _phoneController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'weight': !_isSpecialistAccount ? double.tryParse(_weightController.text) : null,
        'height': !_isSpecialistAccount ? double.tryParse(_heightController.text) : null,
        'gender': _gender,
        'category': _category,
        'account_type': _isSpecialistAccount ? 'specialist' : 'user',
        'specialization': _isSpecialistAccount ? _specialization : null,
        'abba_id': _isSpecialistAccount ? _idController.text : null,
        'certifications': _isSpecialistAccount ? _certController.text : null,
        'is_abha_verified': _isSpecialistAccount ? true : false,
      };

      await Supabase.instance.client.from('user_data').upsert(profileData);

      if (mounted) {
        if (_isSpecialistAccount) {
          // Specialist Mock Navigation
          final specialistData = UserData(
            name: _nameController.text,
            email: user.email!,
            age: int.tryParse(_ageController.text) ?? 30,
            gender: _gender,
            category: 'Expert',
            accountType: AccountType.specialist,
            isAbhaVerified: true,
            specialization: _specialization,
          );
          Navigator.pushReplacementNamed(context, '/specialist-dashboard', arguments: specialistData);
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Hero(
                  tag: 'logo',
                  child: Image.asset('assets/logo.jpeg', width: 80, height: 80),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Complete Your Profile',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us personalize your health journey.',
                style: TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 32),
              _buildField('Full Name', Icons.person_outline_rounded, controller: _nameController),
              const SizedBox(height: 16),
              _buildField('Email Address', Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField('Phone Number', Icons.phone_android_rounded, controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Age', Icons.calendar_today_rounded, controller: _ageController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded)),
                      items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isSpecialistAccount) ...[
                Row(
                  children: [
                    Expanded(child: _buildField('Weight (kg)', Icons.monitor_weight_outlined, controller: _weightController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Height (cm)', Icons.height_rounded, controller: _heightController, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                  items: ['Teenager', 'Working Professional', 'Housewife', 'Senior Citizen']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _specialization,
                  decoration: const InputDecoration(labelText: 'Your Specialty', prefixIcon: Icon(Icons.medical_services_outlined)),
                  items: ['Physiotherapist', 'Nutritionist', 'Yoga Teacher']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _specialization = val!),
                ),
                const SizedBox(height: 16),
                _buildField('Certifications & Experience', Icons.workspace_premium_outlined, controller: _certController),
                const SizedBox(height: 16),
                _buildField('ABHA / National Provider ID', Icons.verified_user_rounded, controller: _idController),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, {required TextEditingController controller, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

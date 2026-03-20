import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class PermissionScreen extends StatefulWidget {
  final bool isSpecialist;
  const PermissionScreen({super.key, this.isSpecialist = false});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _storageGranted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    final storage = await Permission.storage.isGranted || await Permission.photos.isGranted;
    
    setState(() {
      _cameraGranted = camera;
      _micGranted = mic;
      _storageGranted = storage;
    });
  }

  Future<void> _requestAll() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
    ].request();

    setState(() {
      _cameraGranted = statuses[Permission.camera]!.isGranted;
      _micGranted = statuses[Permission.microphone]!.isGranted;
      _storageGranted = statuses[Permission.storage]!.isGranted || statuses[Permission.photos]!.isGranted;
    });

    if (_cameraGranted && _micGranted && _storageGranted) {
      _navigateNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant all permissions to continue!')),
      );
    }
  }

  void _navigateNext() {
    if (widget.isSpecialist) {
      Navigator.pushReplacementNamed(context, '/specialist-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.security_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Unlock Full Potential',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'To provide the best health experience, VitaAI needs access to your camera and sensors.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    _buildPermRow(Icons.camera_alt_rounded, 'Camera', 'For food scanning & label analysis', _cameraGranted),
                    _buildPermRow(Icons.mic_rounded, 'Microphone', 'For consultations & demo calls', _micGranted),
                    _buildPermRow(Icons.photo_library_rounded, 'Storage', 'To save reports & upload lab results', _storageGranted),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _requestAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Allow All Access', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateNext,
                      child: const Text('I\'ll do it later', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermRow(IconData icon, String title, String subtitle, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isGranted ? Colors.green : Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../screens/demo_call_screen.dart';
import '../screens/agora_call_screen.dart';
import '../../../services/stream_service.dart';

class UnifiedConsultationModal extends StatefulWidget {
  const UnifiedConsultationModal({super.key});

  @override
  State<UnifiedConsultationModal> createState() => _UnifiedConsultationModalState();
}

class _UnifiedConsultationModalState extends State<UnifiedConsultationModal> {
  final TextEditingController _codeController = TextEditingController(text: 'test');
  String? _generatedCode;
  bool _isJoining = false;

  void _generateCode() {
    setState(() {
      _generatedCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    });
  }

  Future<void> _startCall(String code) async {
    // Show provider selection
    final provider = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Call Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_call, color: Colors.blue),
              title: const Text('Stream Video Call'),
              subtitle: const Text('High quality, low latency'),
              onTap: () => Navigator.pop(context, 'stream'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.orange),
              title: const Text('Agora Video Call'),
              subtitle: const Text('Standard reliability'),
              onTap: () => Navigator.pop(context, 'agora'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (provider == null) return;

    if (provider == 'stream') {
      final hasPermissions = await StreamService.requestPermissions();
      if (hasPermissions) {
        if (mounted) {
           Navigator.pop(context); // Close the modal
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DemoCallScreen(channelId: code)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera and Microphone permissions are required.')),
          );
        }
      }
    } else if (provider == 'agora') {
       final hasPermissions = await StreamService.requestPermissions();
       if (hasPermissions) {
          if (mounted) {
             Navigator.pop(context); // Close the modal
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AgoraCallScreen(channelId: code)),
            );
          }
       } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera and Microphone permissions are required.')),
            );
          }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Video Consultation Hub',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // --- HOST SECTION ---
            _buildSectionTitle('Host a Session'),
            const SizedBox(height: 12),
            if (_generatedCode == null)
              ElevatedButton.icon(
                onPressed: _generateCode,
                icon: const Icon(Icons.add_call),
                label: const Text('Generate Meeting Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _generatedCode!,
                          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedCode!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _startCall(_generatedCode!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Start Now'),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 32),
            
            // --- JOIN SECTION ---
            _buildSectionTitle('Join a Session'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Enter channel name',
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.secondary),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_codeController.text.trim().isNotEmpty) {
                  _startCall(_codeController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a channel name.')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Join with Code'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 1),
    );
  }
}

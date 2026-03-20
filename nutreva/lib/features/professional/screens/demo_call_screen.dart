import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/theme.dart';
import '../../../core/user_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/health_service.dart';
import '../../../services/stream_service.dart';
import 'package:open_file/open_file.dart';

class DemoCallScreen extends StatefulWidget {
  final String channelId;
  const DemoCallScreen({super.key, this.channelId = 'test_channel'});

  @override
  State<DemoCallScreen> createState() => _DemoCallScreenState();
}

class _DemoCallScreenState extends State<DemoCallScreen> {
  bool _isInit = false;
  late stream.StreamVideo _client;
  late stream.Call _call;
  int _secondsRemaining = 120;
  Timer? _timer;
  
  // Track camera and mic state for custom controls
  bool _isCameraEnabled = true;
  bool _isMicEnabled = true;


  @override
  void initState() {
    super.initState();
    _initStream();
    _startTimer();
  }

  Future<void> _initStream() async {
    try {
      await StreamService.requestPermissions();

      final user = supabase.Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final token = StreamService.createToken(userId);

      _client = StreamService.initializeClient(userId, token);
      
      _call = _client.makeCall(
        callType: stream.StreamCallType.defaultType(), 
        id: widget.channelId,
      );
      
      await _call.getOrCreate();
      
      // Explicitly enabled media using correct 1.2.4 SDK methods.
      await _call.setCameraEnabled(enabled: true);
      await _call.setMicrophoneEnabled(enabled: true);
      
      // We call join() to connect to the signaling and media server.
      final result = await _call.join();
      
      if (result.isSuccess) {
         debugPrint("Stream Call Joined Successfully: ${result.getDataOrNull()}");
      } else {
         debugPrint("Stream Call Join Failed: $result");
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to join call: $result')),
           );
         }
      }
      
      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing Stream Call: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error initializing call: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _endCall();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _endCall() async {
    _timer?.cancel();
    try {
      await _call.leave();
      
      final healthService = HealthService();
      final userProfile = UserData(
        name: healthService.currentData.userName,
        email: healthService.currentData.email,
        phone: healthService.currentData.phone,
        age: 28,
        gender: 'Male',
        weight: healthService.currentData.weight,
        height: healthService.currentData.height,
        category: 'Working Professional',
      );

      final paymentService = PaymentService();
      final receiptFile = await PdfService.generateTaxInvoice(userProfile, 'Dr. Sarah Smith', 499.0);

      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await paymentService.processSpecialistPayment(
          userId: currentUser.id,
          specialistId: 'spec_123',
          amount: 499.0,
          serviceType: 'Online Consultation',
          receiptFile: receiptFile,
        );
      }

      if (mounted) {
        // Capture context before popping
        final navigator = Navigator.of(context);
        navigator.pop();
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Consultation Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment of ₹499.0 processed successfully.'),
                  const SizedBox(height: 12),
                  const Text('Blockchain Verified (Solana):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Tx: 5Kj3...9zB2', style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.green)),
                  const SizedBox(height: 12),
                  const Text('Tax Invoice generated & sent to your email.', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => OpenFile.open(receiptFile.path),
                  child: const Text('View Invoice'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _showCallStats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final state = _call.state.value;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Call Statistics',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatItem('Call ID', _call.id),
                _buildStatItem('Session ID', state.sessionId),
                _buildStatItem('User ID', _client.currentUser.id),
                _buildStatItem('Participants', '${state.callParticipants.length}'),
                _buildStatItem('Status', state.status.toString()),
                const Divider(color: Colors.white24, height: 32),
                Text(
                  'Media Stats',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Real-time stats are available in the debug console.',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _call.leave();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video participants view
          Positioned.fill(
            child: stream.StreamCallParticipants(
              call: _call,
            ),
          ),
          
          // Custom control bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: _buildCustomControls(),
          ),
          
          // Timer Overlay at top
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom control bar widget
  Widget _buildCustomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
            label: 'Mic',
            isActive: _isMicEnabled,
            onPressed: _toggleMicrophone,
          ),
          _buildControlButton(
            icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
            label: 'Camera',
            isActive: _isCameraEnabled,
            onPressed: _toggleCamera,
          ),
          _buildControlButton(
            icon: Icons.cameraswitch,
            label: 'Flip',
            onPressed: _flipCamera,
          ),
          _buildControlButton(
            icon: Icons.info_outline,
            label: 'Stats',
            onPressed: () => _showCallStats(context),
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            color: Colors.red,
            onPressed: _endCall,
          ),
        ],
      ),
    );
  }

  // Individual control button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = true,
    Color? color,
    required VoidCallback onPressed,
  }) {
    final buttonColor = color ?? (isActive ? AppColors.primary : Colors.grey);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Toggle microphone
  Future<void> _toggleMicrophone() async {
    try {
      await _call.setMicrophoneEnabled(enabled: !_isMicEnabled);
      setState(() {
        _isMicEnabled = !_isMicEnabled;
      });
    } catch (e) {
      debugPrint('Error toggling microphone: $e');
    }
  }

  // Toggle camera
  Future<void> _toggleCamera() async {
    try {
      await _call.setCameraEnabled(enabled: !_isCameraEnabled);
      setState(() {
        _isCameraEnabled = !_isCameraEnabled;
      });
    } catch (e) {
      debugPrint('Error toggling camera: $e');
    }
  }

  // Flip camera
  Future<void> _flipCamera() async {
    try {
      await _call.flipCamera();
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

}

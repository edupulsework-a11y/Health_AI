import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/stream_service.dart';

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
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final token = StreamService.createToken(userId);

      _client = StreamService.initializeClient(userId, token);
      _call = _client.makeCall(
        callType: stream.StreamCallType.defaultType(),
        id: widget.channelId,
      );

      await _call.getOrCreate();
      await _call.setCameraEnabled(enabled: true);
      await _call.setMicrophoneEnabled(enabled: true);

      final result = await _call.join();
      if (!result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to join: $result')));
      }
      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else { t.cancel(); _endCall(); }
    });
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  void _endCall() async {
    _timer?.cancel();
    try { await _call.leave(); } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Consultation Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment of 0.005 ETH processed via smart contract.'),
              const SizedBox(height: 10),
              Text('Blockchain TX saved to Supabase.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
    }
  }

  Future<void> _toggleMic() async {
    try {
      await _call.setMicrophoneEnabled(enabled: !_isMicEnabled);
      setState(() => _isMicEnabled = !_isMicEnabled);
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    try {
      await _call.setCameraEnabled(enabled: !_isCameraEnabled);
      setState(() => _isCameraEnabled = !_isCameraEnabled);
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    try { await _call.flipCamera(); } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    try { _call.leave(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          stream.StreamCallParticipants(call: _call),
          // Timer overlay
          Positioned(
            top: 50, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(_fmt(_secondsRemaining),
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ]),
              ),
            ),
          ),
          // Controls
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ctrl(icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
                  label: 'Mic', isActive: _isMicEnabled, onTap: _toggleMic),
              _ctrl(icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                  label: 'Camera', isActive: _isCameraEnabled, onTap: _toggleCamera),
              _ctrl(icon: Icons.cameraswitch, label: 'Flip', onTap: _flipCamera),
              _ctrl(icon: Icons.call_end, label: 'End', color: Colors.red, onTap: _endCall),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _ctrl({required IconData icon, required String label,
      bool isActive = true, Color? color, required VoidCallback onTap}) {
    final c = color ?? (isActive ? AppColors.primaryTeal : Colors.grey);
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: c.withAlpha(220), shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}

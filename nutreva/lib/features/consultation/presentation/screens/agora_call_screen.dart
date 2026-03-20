import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class AgoraCallScreen extends StatefulWidget {
  final String channelId;
  const AgoraCallScreen({super.key, this.channelId = 'test_channel'});

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  int _secondsRemaining = 120;
  Timer? _timer;
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startTimer();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AppConstants.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (_, __) => setState(() => _localUserJoined = true),
      onUserJoined: (_, uid, __) => setState(() => _remoteUid = uid),
      onUserOffline: (_, __, ___) => setState(() => _remoteUid = null),
      onError: (err, msg) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agora Error: $err')));
      },
    ));

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: AppConstants.agoraTempToken,
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else { t.cancel(); _endCall(); }
    });
  }

  void _endCall() async {
    _timer?.cancel();
    try { await _engine.leaveChannel(); await _engine.release(); } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
      _showPaymentDialog();
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Consultation Complete'),
        content: const Text('Payment of 0.005 ETH processed via smart contract.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: _remoteVideo()),
          // Local preview PiP
          Positioned(
            top: 60,
            left: 20,
            width: 120,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _localUserJoined
                    ? AgoraVideoView(controller: VideoViewController(
                        rtcEngine: _engine, canvas: const VideoCanvas(uid: 0)))
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          ),
          // Timer
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
            bottom: 60, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ctrl(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  _isMuted ? Colors.red : Colors.white24, () {
                setState(() => _isMuted = !_isMuted);
                _engine.muteLocalAudioStream(_isMuted);
              }),
              _ctrl(Icons.call_end_rounded, Colors.red, _endCall),
              _ctrl(_isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                  _isVideoOff ? Colors.red : Colors.white24, () {
                setState(() => _isVideoOff = !_isVideoOff);
                _engine.muteLocalVideoStream(_isVideoOff);
              }),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    }
    return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: Colors.white),
      SizedBox(height: 20),
      Text('Waiting for expert to join...', style: TextStyle(color: Colors.white70)),
    ]);
  }

  Widget _ctrl(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

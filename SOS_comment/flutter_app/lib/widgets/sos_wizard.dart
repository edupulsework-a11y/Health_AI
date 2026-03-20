import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/notification_service.dart';

class SOSWizard extends StatefulWidget {
  final VoidCallback onCancel;
  final String guardianNumber;

  const SOSWizard({
    super.key,
    required this.onCancel,
    required this.guardianNumber,
  });

  @override
  State<SOSWizard> createState() => _SOSWizardState();
}

class _SOSWizardState extends State<SOSWizard> {
  int _timerValue = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue > 0) {
        setState(() => _timerValue--);
      } else {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  Future<void> _triggerSOS() async {
    // 1. Capture Location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (_) {}

    // 2. Capture Photos (Simplified)
    List<String> photoPaths = [];
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(cameras[0], ResolutionPreset.low);
        await controller.initialize();
        final xFile = await controller.takePicture();
        photoPaths.add(xFile.path);
        await controller.dispose();
      }
    } catch (_) {}

    // 3. Prepare SOS Content
    final locationUrl = position != null 
        ? 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}'
        : 'Unknown Location';

    final sosMessage = '🚨 EMERGENCY SOS! I have fallen!\n'
                       '📍 My Live Location: $locationUrl\n'
                       'Please help!';

    // 4. Dispatch
    if (photoPaths.isNotEmpty) {
      await Share.shareXFiles(
        [XFile(photoPaths[0])],
        text: sosMessage,
      );
    } else {
      final whatsappUrl = 'whatsapp://send?phone=${widget.guardianNumber}&text=${Uri.encodeComponent(sosMessage)}';
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        await Share.share(sosMessage);
      }
    }

    // Cancel system alert and close
    await NotificationService.cancelAlert();
    if (mounted) widget.onCancel();
  }

  void _handleCancel() async {
    await NotificationService.cancelAlert();
    widget.onCancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              const Text(
                'FALL DETECTED!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sending SOS in:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.red,
                child: Text(
                  '$_timerValue',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Are you okay?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleCancel,
                      child: const Text('I AM OKAY', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

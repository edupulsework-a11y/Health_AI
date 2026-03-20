import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.initialize();

  // Accelerometer Stream
  accelerometerEventStream().listen((AccelerometerEvent event) {
    double magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );

    // Balanced free fall threshold (~ 1.8 m/s^2) 
    // Sensitive enough for pillow drops, but filters normal movement.
    if (magnitude < 1.8) {
      // Trigger system-level SOS alert
      NotificationService.showFallAlert();
      
      // Notify the app (if open) to show the overlay
      service.invoke('fall_detected');
    }
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

class FallDetectionService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'sos_channel',
        initialNotificationTitle: 'Safety Guard Active',
        initialNotificationContent: 'Monitoring for falls 24/7',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }
}

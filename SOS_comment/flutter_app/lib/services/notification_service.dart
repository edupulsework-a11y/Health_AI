import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    
    // Create the SOS channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sos_channel',
      'Emergency SOS',
      description: 'Critical fall detection alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showFallAlert() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'Emergency SOS',
      channelDescription: 'Critical fall detection alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true, // This is key for waking up the phone
      ongoing: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      999,
      '🚨 FALL DETECTED!',
      'Tap to cancel the SOS countdown!',
      notificationDetails,
    );
  }

  static Future<void> cancelAlert() async {
    await _notificationsPlugin.cancel(999);
  }
}

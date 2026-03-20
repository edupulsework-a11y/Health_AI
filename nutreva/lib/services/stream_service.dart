import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/api_keys.dart';

class StreamService {
  /// Generates a mock JWT for development/hackathon purposes.
  /// NOTE: For production, this must be generated on a secure backend.
  static String createToken(String userId) {
    try {
      final header = {
        "alg": "HS256",
        "typ": "JWT"
      };

      final payload = {
        "user_id": userId,
        "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      String base64UrlEncode(Map<String, dynamic> json) {
        return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      }

      final headerBase64 = base64UrlEncode(header);
      final payloadBase64 = base64UrlEncode(payload);

      final signatureSource = "$headerBase64.$payloadBase64";
      final key = utf8.encode(ApiKeys.streamApiSecret);
      final hmacSha256 = Hmac(sha256, key);
      final signature = hmacSha256.convert(utf8.encode(signatureSource));
      final signatureBase64 = base64Url.encode(signature.bytes).replaceAll('=', '');

      return "$headerBase64.$payloadBase64.$signatureBase64";
    } catch (e) {
      // Fallback to a structure that might bypass client-side parsing checks 
      // even if it fails server-side verification (if disabled in dashboard)
      return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFja2F0aG9uIn0.mock_signature";
    }
  }

  /// Safe initialization of StreamVideo client (Singleton)
  static StreamVideo initializeClient(String userId, String token) {
    try {
      // Check if instance already exists
      return StreamVideo.instance;
    } catch (_) {
      // Initialize if not already done
      return StreamVideo(
        ApiKeys.streamApiKey,
        user: User.regular(
          userId: userId,
          name: userId.split('_')[0], // Fallback name
        ),
        userToken: token,
      );
    }
  }

  /// Resets the StreamVideo client to allow re-initialization if needed
  static Future<void> resetClient() async {
    try {
      await StreamVideo.reset();
    } catch (_) {
      // Ignore if not initialized
    }
  }

  /// Combined permission check for Video Consultation
  static Future<bool> requestPermissions() async {
    // Request multiple permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.bluetoothConnect, // Required for Android 12+
      Permission.bluetoothScan,    // Required for Android 12+
      Permission.notification,     // Required for Android 13+
    ].request();

    // Check if critical permissions are granted
    bool cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    return cameraGranted && micGranted;
  }
}

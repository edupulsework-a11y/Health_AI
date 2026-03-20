import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ──────────────────────────────────────────
final sensorDataProvider = StreamProvider<SensorData>((ref) {
  return FirebaseSensorService().sensorStream();
});

final latestSensorProvider = Provider<AsyncValue<SensorData>>((ref) {
  return ref.watch(sensorDataProvider);
});

// ── Model ─────────────────────────────────────────────
class SensorData {
  final double temperature;
  final double humidity;
  final int gasPpm;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.gasPpm,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      gasPpm: (map['gas'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.now(),
    );
  }

  /// Simple food safety score based on sensor readings:
  /// - Gas > 400 ppm  → Likely spoiled / contaminated
  /// - Humidity > 80% → High moisture, mold risk
  /// - Temp > 40°C    → Unsafe storage temp
  String get safetyStatus {
    if (gasPpm > 400) return 'Unsafe';
    if (gasPpm > 250 || humidity > 80 || temperature > 40) return 'Moderate';
    return 'Good';
  }

  @override
  String toString() =>
      'Temp: ${temperature.toStringAsFixed(1)}°C, '
      'Humidity: ${humidity.toStringAsFixed(1)}%, '
      'Gas: $gasPpm ppm';
}

// ── Service ───────────────────────────────────────────
class FirebaseSensorService {
  static const String _sensorPath = '/sensors';

  final DatabaseReference _ref = FirebaseDatabase.instance.ref(_sensorPath);

  /// Live stream of sensor data from ESP8266 via Firebase RTDB
  Stream<SensorData> sensorStream() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return _empty();
      return SensorData.fromMap(data as Map<dynamic, dynamic>);
    });
  }

  /// One-time fetch of current sensor values
  Future<SensorData> fetchOnce() async {
    final snapshot = await _ref.get();
    if (!snapshot.exists) return _empty();
    return SensorData.fromMap(snapshot.value as Map<dynamic, dynamic>);
  }

  SensorData _empty() => SensorData(
        temperature: 0,
        humidity: 0,
        gasPpm: 0,
        timestamp: DateTime.now(),
      );
}

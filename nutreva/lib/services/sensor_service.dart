import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class SensorService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  // Stream of sensor data from Firebase
  Stream<Map<String, dynamic>> getSensorDataStream() {
    return _db.ref('sensor_readings').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return Map<String, dynamic>.from(data);
    });
  }

  // Get current snapshot
  Future<Map<String, dynamic>> getCurrentSensorData() async {
    final snapshot = await _db.ref('sensor_readings').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }

  // Logic for food freshness based on gas level
  String getFoodStatus(int gasLevel) {
    if (gasLevel < 200) {
      return "Fresh & Safe to Eat";
    } else if (gasLevel >= 200 && gasLevel <= 400) {
      return "Eat Fast - Getting Ripe";
    } else {
      return "Throw It - Spoiled / High Gas";
    }
  }
}

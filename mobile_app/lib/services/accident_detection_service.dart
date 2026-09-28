import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../services/emergency_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccidentDetectionService {
  static const double ACCIDENT_THRESHOLD =
      50.0; // m/s² (approximately 5G) - Increased to reduce false alarms

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastAccidentCheck;
  DateTime? _startupTime;
  final EmergencyService _emergencyService = EmergencyService();

  void startMonitoring(BuildContext context) {
    _startupTime = DateTime.now(); // Record startup time

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      final now = DateTime.now();

      // Ignore readings for first 5 seconds after startup (settling period)
      if (_startupTime != null &&
          now.difference(_startupTime!) < const Duration(seconds: 5)) {
        return;
      }

      // Check cooldown (prevent multiple triggers)
      if (_lastAccidentCheck != null &&
          now.difference(_lastAccidentCheck!) < const Duration(seconds: 30)) {
        return;
      }

      // Calculate total acceleration magnitude using CORRECT formula: sqrt(x² + y² + z²)
      final double totalAcceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (totalAcceleration > ACCIDENT_THRESHOLD) {
        _lastAccidentCheck = now;
        debugPrint(
            '🚨 ACCIDENT DETECTED! Acceleration: ${totalAcceleration.toStringAsFixed(2)} m/s²');

        _handleAccidentDetected(context, totalAcceleration);
      }
    });
  }

  Future<void> _handleAccidentDetected(
      BuildContext context, double acceleration) async {
    final accidentData = {
      'acceleration_g': acceleration / 9.81, // Convert to G-force
      'timestamp': DateTime.now().toIso8601String(),
      'gps': 'Retrieving...',
    };

    // Show emergency modal with countdown
    _emergencyService.showAccidentModal(context, accidentData);

    // Report to backend
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl =
          prefs.getString('backend_url') ?? 'http://192.168.1.159:8000';

      if (token != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/emergency/accident'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(accidentData),
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Accident reported to backend');
        }
      }
    } catch (e) {
      debugPrint('❌ Error reporting accident: $e');
    }
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void dispose() {
    stopMonitoring();
    _emergencyService.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class EmergencyService {
  static const String DEFAULT_EMERGENCY_NUMBER = '112'; // Default fallback
  static const int COUNTDOWN_SECONDS = 10;

  Timer? _countdownTimer;
  int _remainingSeconds = COUNTDOWN_SECONDS;

  /// Load emergency contact from preferences
  Future<String> _getEmergencyNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emergency_phone') ?? DEFAULT_EMERGENCY_NUMBER;
  }

  /// Load custom emergency message from preferences
  Future<String> _getEmergencyMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emergency_message') ??
        '🚨 ACCIDENT DÉTECTÉ PAR HANINY\nJ\'ai besoin d\'aide immédiatement!';
  }

  Future<void> showAccidentModal(
    BuildContext context,
    Map<String, dynamic> accidentData,
  ) async {
    _remainingSeconds = COUNTDOWN_SECONDS;
    bool cancelled = false;

    // Load emergency number
    final emergencyNumber = await _getEmergencyNumber();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Démarrer le compte à rebours
          if (_countdownTimer == null || !_countdownTimer!.isActive) {
            _countdownTimer = Timer.periodic(
              Duration(seconds: 1),
              (timer) {
                if (_remainingSeconds > 0) {
                  setState(() {
                    _remainingSeconds--;
                  });
                } else {
                  // Temps écoulé → Appel d'urgence
                  timer.cancel();
                  Navigator.of(context).pop();

                  if (!cancelled) {
                    _executeEmergencyProcedure(context, accidentData);
                  }
                }
              },
            );
          }

          return AlertDialog(
            backgroundColor: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.red, width: 3),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ACCIDENT DÉTECTÉ',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône danger animée
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_remainingSeconds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Appel des secours dans $_remainingSeconds secondes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Numéro: $emergencyNumber',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 10),
                if (accidentData['gps'] != null)
                  Text(
                    'Position GPS enregistrée',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            actions: [
              // Bouton d'annulation GROS et visible
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    cancelled = true;
                    _countdownTimer?.cancel();
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appel d\'urgence annulé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'JE VAIS BIEN - ANNULER',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Procédure d'urgence complète
  Future<void> _executeEmergencyProcedure(
    BuildContext context,
    Map<String, dynamic> accidentData,
  ) async {
    print('🚨 EXÉCUTION PROCÉDURE D\'URGENCE');

    // 1. Obtenir la position GPS actuelle
    Position? position = await _getCurrentPosition();

    // 2. Envoyer SMS d'urgence
    await _sendEmergencySMS(position, accidentData);

    // 3. Envoyer au serveur (TODO: Implement backend endpoint if needed)
    // await _sendToServer(accidentData, position);

    // 4. Appeler les secours
    await _callEmergency();

    // 5. Notification locale
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Secours contactés automatiquement'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  /// Obtenir position GPS
  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Erreur GPS: $e');
      return null;
    }
  }

  Future<void> _sendEmergencySMS(
    Position? position,
    Map<String, dynamic> accidentData,
  ) async {
    // Load custom message and emergency number
    final baseMessage = await _getEmergencyMessage();
    final emergencyNumber = await _getEmergencyNumber();

    String message = baseMessage + '\n\n';

    if (position != null) {
      message +=
          'Position: https://maps.google.com/?q=${position.latitude},${position.longitude}\n';
      message += 'Lat: ${position.latitude.toStringAsFixed(6)}\n';
      message += 'Lon: ${position.longitude.toStringAsFixed(6)}\n';
    } else {
      message += 'Position GPS non disponible\n';
    }

    message +=
        'Impact: ${accidentData['acceleration_g']?.toStringAsFixed(2)}G\n';
    message += 'Heure: ${DateTime.now().toString()}';

    try {
      // Use url_launcher to open SMS app with pre-filled message
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: emergencyNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('✅ SMS app opened successfully');
      } else {
        debugPrint('❌ Cannot launch SMS app');
      }
    } catch (e) {
      debugPrint('❌ Error sending SMS: $e');
    }
  }

  /// Appeler les secours
  Future<void> _callEmergency() async {
    final emergencyNumber = await _getEmergencyNumber();
    try {
      await FlutterPhoneDirectCaller.callNumber(emergencyNumber);
      print('✓ Appel vers $emergencyNumber initié');
    } catch (e) {
      print('❌ Erreur appel: $e');
    }
  }

  /// Cleanup
  void dispose() {
    _countdownTimer?.cancel();
  }
}

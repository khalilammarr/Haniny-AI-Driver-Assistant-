import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  final VoidCallback onCameraToggle;
  final VoidCallback onMonitoringToggle;
  final bool isCameraEnabled;
  final bool isMonitoring;

  const ControlButtonsWidget({
    Key? key,
    required this.onCameraToggle,
    required this.onMonitoringToggle,
    required this.onSimulateAccident,
    required this.isCameraEnabled,
    required this.isMonitoring,
  }) : super(key: key);

  final VoidCallback onSimulateAccident;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Test buttons removed as requested
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onCameraToggle,
                  icon: Icon(
                      isCameraEnabled ? Icons.videocam : Icons.videocam_off),
                  label: Text(
                    isCameraEnabled ? 'Caméra ON' : 'Caméra OFF',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCameraEnabled ? const Color(0xFF7FC8A9) : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onMonitoringToggle,
                  icon: Icon(
                      isMonitoring ? Icons.stop_circle : Icons.play_circle),
                  label: Text(
                    isMonitoring ? 'Arrêter' : 'Démarrer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMonitoring
                        ? const Color(0xFFFF8C42)
                        : const Color(0xFF7FC8A9),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

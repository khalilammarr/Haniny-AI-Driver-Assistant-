import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? driverCam;
  final CameraController? roadCam;
  final CameraController? activeCamera;
  final bool isDriverCamActive;
  final bool isMonitoring;
  final Animation<double> pulseAnimation;
  final VoidCallback onSwitchCamera;

  const CameraPreviewWidget({
    Key? key,
    required this.driverCam,
    required this.roadCam,
    required this.activeCamera,
    required this.isDriverCamActive,
    required this.isMonitoring,
    required this.pulseAnimation,
    required this.onSwitchCamera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _buildActiveCameraCard(),
    );
  }

  Widget _buildActiveCameraCard() {
    final isActive = activeCamera?.value.isInitialized == true;
    final label = isDriverCamActive ? 'Conducteur (Selfie)' : 'Route (Avant)';
    final icon = isDriverCamActive ? Icons.person : Icons.drive_eta;
    final nextCameraLabel = isDriverCamActive ? 'Route' : 'Conducteur';
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF7FC8A9).withOpacity(0.8) : Colors.white.withOpacity(0.2),
          width: 3,
        ),
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          if (isActive)
            BoxShadow(
              color: const Color(0xFF7FC8A9).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isActive
                ? CameraPreview(activeCamera!)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Caméra désactivée',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
            
            // Label de la caméra active
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF7FC8A9)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Indicateur de surveillance (point rouge pulsant)
            if (isMonitoring && isActive)
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: pulseAnimation.value,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C42),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C42).withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Bouton pour changer de caméra
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSwitchCamera,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7FC8A9).withOpacity(0.9),
                          const Color(0xFF6BB395).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7FC8A9).withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nextCameraLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Statut de la caméra (actif/inactif)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive 
                      ? const Color(0xFF7FC8A9).withOpacity(0.9)
                      : Colors.grey.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
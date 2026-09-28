import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapCardWidget extends StatelessWidget {
  final MapController mapController;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;
  final double speed;
  final Animation<double> pulseAnimation;

  const MapCardWidget({
    Key? key,
    required this.mapController,
    required this.routePoints,
    required this.currentPosition,
    required this.speed,
    required this.pulseAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultPosition = LatLng(48.8566, 2.3522);
    final center = currentPosition ?? defaultPosition;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.driver_safety',
                  maxZoom: 19,
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 3.0,
                        color: const Color(0xFF7FC8A9),
                        borderStrokeWidth: 1.5,
                        borderColor: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                if (currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentPosition!,
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 40 * pulseAnimation.value,
                                  height: 40 * pulseAnimation.value,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7FC8A9).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7FC8A9),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            if (speed > 1.0)
                              Positioned(
                                top: 0,
                                child: Icon(
                                  Icons.navigation,
                                  color: const Color(0xFF7FC8A9),
                                  size: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentPosition != null ? Icons.gps_fixed : Icons.gps_off,
                    size: 16,
                    color: currentPosition != null 
                        ? const Color(0xFF7FC8A9) 
                        : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentPosition != null ? 'GPS Actif' : 'Paris',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: currentPosition != null 
                          ? const Color(0xFF7FC8A9) 
                          : const Color(0xFF2D4739),
                    ),
                  ),
                  if (routePoints.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${routePoints.length})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _buildMapButton(Icons.add, () {
                  final currentZoom = mapController.camera.zoom;
                  mapController.move(
                    mapController.camera.center,
                    currentZoom + 1,
                  );
                }),
                const SizedBox(height: 8),
                _buildMapButton(Icons.remove, () {
                  final currentZoom = mapController.camera.zoom;
                  mapController.move(
                    mapController.camera.center,
                    currentZoom - 1,
                  );
                }),
                const SizedBox(height: 8),
                _buildMapButton(
                  Icons.my_location,
                  currentPosition != null
                      ? () {
                          mapController.move(currentPosition!, 15.0);
                        }
                      : null,
                  color: currentPosition != null 
                      ? const Color(0xFF7FC8A9) 
                      : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback? onPressed, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color ?? const Color(0xFF7FC8A9),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

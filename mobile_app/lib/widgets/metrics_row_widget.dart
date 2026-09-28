import 'package:flutter/material.dart';

class MetricsRowWidget extends StatelessWidget {
  final double speed;
  final double acceleration;

  const MetricsRowWidget({
    Key? key,
    required this.speed,
    required this.acceleration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.speed,
            label: 'Vitesse',
            value: speed.toStringAsFixed(0),
            unit: 'km/h',
            color: const Color(0xFFFF8C42),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.trending_up,
            label: 'Accélération',
            value: acceleration.toStringAsFixed(2),
            unit: 'm/s²',
            color: const Color(0xFF7FC8A9),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF5F7A6A).withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

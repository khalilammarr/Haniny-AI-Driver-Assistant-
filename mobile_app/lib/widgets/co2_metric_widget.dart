import 'package:flutter/material.dart';
import '../services/co2_calculator.dart';

class CO2MetricWidget extends StatelessWidget {
  final double emissionRate; // g/km
  final double totalCO2; // grams

  const CO2MetricWidget({
    Key? key,
    required this.emissionRate,
    required this.totalCO2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final level = CO2Calculator.getEmissionLevel(emissionRate);
    final icon = CO2Calculator.getEmissionIcon(level);

    Color color;
    switch (level) {
      case EmissionLevel.eco:
        color = const Color(0xFF4CAF50);
        break;
      case EmissionLevel.moderate:
        color = const Color(0xFFFFA726);
        break;
      case EmissionLevel.high:
        color = const Color(0xFFE53935);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                'Émissions CO₂',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current emission rate
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${emissionRate.toStringAsFixed(0)} g/km',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Taux actuel',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Total CO2 for trip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CO2Calculator.formatCO2(totalCO2),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Total trajet',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Emission level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level == EmissionLevel.eco
                  ? 'Conduite écologique 🌱'
                  : level == EmissionLevel.moderate
                      ? 'Émissions modérées'
                      : 'Émissions élevées!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

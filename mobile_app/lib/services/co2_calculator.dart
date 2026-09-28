import 'dart:math';

/// Service to calculate CO2 emissions based on driving behavior
class CO2Calculator {
  // Base emission rate for a typical gasoline car (grams CO2 per km)
  static const double BASE_EMISSION_RATE = 120.0;

  // Thresholds for emission alerts
  static const double ECO_THRESHOLD = 150.0; // Green zone
  static const double MODERATE_THRESHOLD = 200.0; // Yellow zone
  // Above MODERATE_THRESHOLD = Red zone

  /// Calculate instantaneous CO2 emission rate in g/km
  static double calculateEmissionRate(double speed, double acceleration) {
    // 1. Speed factor (optimal speed is 50-80 km/h)
    double speedFactor = 1.0;
    if (speed < 20) {
      speedFactor = 1.3; // Idling/very slow = inefficient
    } else if (speed > 100) {
      speedFactor = 1.0 + (speed - 100) * 0.01; // High speed = more drag
    }

    // 2. Acceleration factor (aggressive acceleration = more fuel)
    double accelFactor = 1.0;
    if (acceleration > 2.0) {
      accelFactor = 1.5; // Hard acceleration
    } else if (acceleration > 1.0) {
      accelFactor = 1.2; // Moderate acceleration
    } else if (acceleration < -2.0) {
      accelFactor = 1.3; // Hard braking (wasted energy)
    }

    // 3. Calculate instantaneous emission rate (g/km)
    double emissionRate = BASE_EMISSION_RATE * speedFactor * accelFactor;

    return emissionRate;
  }

  /// Calculate CO2 emissions per second (grams)
  static double calculateCO2PerSecond(double speed, double acceleration) {
    double emissionRate = calculateEmissionRate(speed, acceleration);

    // Convert g/km to g/s based on current speed
    // CO2 (g/s) = emission_rate (g/km) × speed (km/h) / 3600
    double co2PerSecond = (emissionRate * max(speed, 0)) / 3600.0;

    return co2PerSecond;
  }

  /// Get emission level (eco, moderate, high)
  static EmissionLevel getEmissionLevel(double emissionRate) {
    if (emissionRate < ECO_THRESHOLD) {
      return EmissionLevel.eco;
    } else if (emissionRate < MODERATE_THRESHOLD) {
      return EmissionLevel.moderate;
    } else {
      return EmissionLevel.high;
    }
  }

  /// Get color for emission level
  static String getEmissionColor(EmissionLevel level) {
    switch (level) {
      case EmissionLevel.eco:
        return '0xFF4CAF50'; // Green
      case EmissionLevel.moderate:
        return '0xFFFFA726'; // Orange
      case EmissionLevel.high:
        return '0xFFE53935'; // Red
    }
  }

  /// Get icon for emission level
  static String getEmissionIcon(EmissionLevel level) {
    switch (level) {
      case EmissionLevel.eco:
        return '🌱'; // Eco-friendly
      case EmissionLevel.moderate:
        return '⚠️'; // Warning
      case EmissionLevel.high:
        return '🚨'; // Alert
    }
  }

  /// Format CO2 value for display
  static String formatCO2(double grams) {
    if (grams < 1000) {
      return '${grams.toStringAsFixed(0)}g';
    } else {
      return '${(grams / 1000).toStringAsFixed(2)}kg';
    }
  }
}

enum EmissionLevel {
  eco,
  moderate,
  high,
}

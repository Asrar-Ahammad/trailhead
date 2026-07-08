import 'dart:math';

class TrackingCalcs {
  /// Computes the distance between two points in meters using the Haversine formula.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Filters GPS jumps and poor accuracy coordinates.
  /// Rejects if accuracy is above 30m or if calculated velocity exceeds 12 m/s (~43 km/h).
  static bool isGpsJump(double deltaDist, double deltaTimeS, double accuracy) {
    if (accuracy > 30.0) return true;
    if (deltaTimeS <= 0.0) return false;
    final speed = deltaDist / deltaTimeS;
    if (speed > 12.0) return true;
    return false;
  }

  /// Estimates energy expenditure (calories in Kcal) using MET tables.
  static double? estimateCalories({
    required double? weightKg,
    required double distanceM,
    required int durationS,
  }) {
    if (weightKg == null || durationS <= 0) return null;
    final avgSpeed = distanceM / durationS;
    double met = 1.0;
    if (avgSpeed < 1.38) { // Walk < 5 km/h
      met = 3.5;
    } else if (avgSpeed < 2.22) { // Jog < 8 km/h
      met = 7.0;
    } else if (avgSpeed < 3.33) { // Run < 12 km/h
      met = 10.0;
    } else { // Run fast
      met = 12.5;
    }
    return met * weightKg * (durationS / 3600.0);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/run_tracking/application/tracking_calcs.dart';

void main() {
  group('TrackingCalcs Distance Tests', () {
    test('calculateDistance returns 0 for same point', () {
      final distance = TrackingCalcs.calculateDistance(37.7749, -122.4194, 37.7749, -122.4194);
      expect(distance, closeTo(0.0, 0.01));
    });

    test('calculateDistance calculates correct distance between San Francisco and Los Angeles', () {
      // SF: 37.7749, -122.4194
      // LA: 34.0522, -118.2437
      // Approximately 559 km (559,000 meters)
      final distance = TrackingCalcs.calculateDistance(37.7749, -122.4194, 34.0522, -118.2437);
      expect(distance, closeTo(559000.0, 5000.0)); // within 5km tolerance
    });

    test('calculateDistance calculates correct distance for short run interval', () {
      // Small movement
      final distance = TrackingCalcs.calculateDistance(12.9716, 77.5946, 12.9717, 77.5947);
      expect(distance, closeTo(15.2, 0.5)); // around 15 meters
    });
  });

  group('TrackingCalcs GPS Jump Filter Tests', () {
    test('Rejects points with weak accuracy (> 30m)', () {
      final isJump = TrackingCalcs.isGpsJump(10.0, 5.0, 35.0);
      expect(isJump, isTrue);
    });

    test('Rejects points with excessive speed (> 12 m/s)', () {
      // 100 meters in 5 seconds = 20 m/s (excessive speed for running)
      final isJump = TrackingCalcs.isGpsJump(100.0, 5.0, 10.0);
      expect(isJump, isTrue);
    });

    test('Accepts normal running data', () {
      // 15 meters in 5 seconds = 3 m/s (normal running speed)
      final isJump = TrackingCalcs.isGpsJump(15.0, 5.0, 8.0);
      expect(isJump, isFalse);
    });

    test('Handles zero time delta gracefully without throwing', () {
      final isJump = TrackingCalcs.isGpsJump(10.0, 0.0, 15.0);
      expect(isJump, isFalse);
    });
  });

  group('TrackingCalcs Calorie Estimation Tests', () {
    test('Returns null if user weight is unknown', () {
      final calories = TrackingCalcs.estimateCalories(
        weightKg: null,
        distanceM: 5000.0,
        durationS: 1800,
      );
      expect(calories, isNull);
    });

    test('Returns null if duration is zero or negative', () {
      final calories = TrackingCalcs.estimateCalories(
        weightKg: 70.0,
        distanceM: 1000.0,
        durationS: 0,
      );
      expect(calories, isNull);
    });

    test('Estimates correct calories for jogger (70kg, 5km in 30 mins)', () {
      // Speed = 5000 / 1800 = 2.78 m/s (Run category, MET = 10)
      // Calories = 10 * 70 * (1800 / 3600) = 350 Kcal
      final calories = TrackingCalcs.estimateCalories(
        weightKg: 70.0,
        distanceM: 5000.0,
        durationS: 1800,
      );
      expect(calories, closeTo(350.0, 1.0));
    });

    test('Estimates correct calories for walker (70kg, 2km in 30 mins)', () {
      // Speed = 2000 / 1800 = 1.11 m/s (Walk category, MET = 3.5)
      // Calories = 3.5 * 70 * 0.5 = 122.5 Kcal
      final calories = TrackingCalcs.estimateCalories(
        weightKg: 70.0,
        distanceM: 2000.0,
        durationS: 1800,
      );
      expect(calories, closeTo(122.5, 1.0));
    });
  });
}

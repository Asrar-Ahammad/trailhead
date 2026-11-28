import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/home/domain/home_use_case_weekly_summary.dart';

void main() {
  test(
    'dashboard aggregates daily goals across runs and counts allowed rest days',
    () {
      final summary = calculateWeeklySummary(
        [
          (
            startedAt: DateTime(2026, 11, 25),
            steps: 6000,
            distanceMeters: 5000.0,
            durationSeconds: 1800,
          ),
          (
            startedAt: DateTime(2026, 11, 23, 10),
            steps: 3000,
            distanceMeters: 2000.0,
            durationSeconds: 720,
          ),
          (
            startedAt: DateTime(2026, 11, 23, 8),
            steps: 3000,
            distanceMeters: 3000.0,
            durationSeconds: 1080,
          ),
          (
            startedAt: DateTime(2026, 11, 21),
            steps: 0,
            distanceMeters: 5000.0,
            durationSeconds: 1800,
          ),
        ],
        now: DateTime(2026, 11, 25, 12),
        restDaysLimit: 1,
        dailyMetric: 'steps',
        dailyTarget: 5000,
      );
      expect(summary.distanceKm, 10);
      expect(summary.runCount, 3);
      expect(summary.chartData, [5, 0, 5, 0, 0, 0, 0]);
      expect(summary.streakDays, 3);
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/history/data/run_history_repository.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';

class WeeklySummary {
  final double distanceKm;
  final int runCount;
  final int streakDays;
  final List<double> chartData; // index 0 = Mon, 6 = Sun
  final RunIsar? mostRecentRun;

  WeeklySummary({
    required this.distanceKm,
    required this.runCount,
    required this.streakDays,
    required this.chartData,
    this.mostRecentRun,
  });
}

final weeklySummaryProvider = StreamProvider<WeeklySummary>((ref) {
  final repo = ref.read(runHistoryRepositoryProvider);
  return repo.watchCompletedRuns(limit: 500).map((allRuns) {
    if (allRuns.isEmpty) {
      return WeeklySummary(distanceKm: 0, runCount: 0, streakDays: 0, chartData: List.filled(7, 0.0));
    }

    final now = DateTime.now();
    // Find Monday of the current week (1 = Monday, 7 = Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    
    double totalDistance = 0;
    int runCount = 0;
    List<double> chartData = List.filled(7, 0.0);

    for (final run in allRuns) {
      if (run.startTime != null && !run.startTime!.isBefore(startOfWeek)) {
        runCount++;
        final distKm = (run.distanceM ?? 0) / 1000.0;
        totalDistance += distKm;
        
        // weekday: 1 = Mon, 7 = Sun
        final dayIndex = run.startTime!.weekday - 1;
        chartData[dayIndex] += distKm;
      }
    }

    // Calculate Streak
    int streak = 0;
    DateTime currentDate = now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    
    // Create a set of distinct days the user ran
    final runDays = <DateTime>{};
    for (final run in allRuns) {
      if (run.startTime != null) {
        runDays.add(run.startTime!.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0));
      }
    }

    // Check today or yesterday first
    if (runDays.contains(currentDate)) {
      streak = 1;
    } else {
      final yesterday = currentDate.subtract(const Duration(days: 1));
      if (runDays.contains(yesterday)) {
        streak = 1;
        currentDate = yesterday;
      }
    }

    if (streak > 0) {
      while (true) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        if (runDays.contains(currentDate)) {
          streak++;
        } else {
          break;
        }
      }
    }

    return WeeklySummary(
      distanceKm: totalDistance,
      runCount: runCount,
      streakDays: streak,
      chartData: chartData,
      mostRecentRun: allRuns.first,
    );
  });
});

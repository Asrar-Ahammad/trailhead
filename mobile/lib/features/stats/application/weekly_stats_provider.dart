import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  return repo.watchCompletedRuns(limit: 500).asyncMap((allRuns) async {
    if (allRuns.isEmpty) {
      return WeeklySummary(distanceKm: 0, runCount: 0, streakDays: 0, chartData: List.filled(7, 0.0));
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    
    double totalDistance = 0;
    int runCount = 0;
    List<double> chartData = List.filled(7, 0.0);

    for (final run in allRuns) {
      if (run.startTime != null && !run.startTime!.isBefore(startOfWeek)) {
        runCount++;
        final distKm = (run.distanceM ?? 0) / 1000.0;
        totalDistance += distKm;
        final dayIndex = run.startTime!.weekday - 1;
        chartData[dayIndex] += distKm;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final restDaysLimit = prefs.getInt('rest_days_limit') ?? 0;

    int streak = 0;
    
    final runDays = <DateTime>{};
    for (final run in allRuns) {
      if (run.startTime != null) {
        runDays.add(run.startTime!.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0));
      }
    }

    final sortedDays = runDays.toList()..sort();
    
    int currentCount = 0;
    DateTime? prevDate;
    int currentMonth = -1;
    int restDaysRemaining = restDaysLimit;

    for (final date in sortedDays) {
      if (date.month != currentMonth) {
        currentMonth = date.month;
        restDaysRemaining = restDaysLimit;
      }

      if (prevDate == null) {
        currentCount = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentCount++;
        } else if (diff > 1) {
          final missedDays = diff - 1;
          if (missedDays <= restDaysRemaining) {
            restDaysRemaining -= missedDays;
            currentCount++; // Count only the run day
          } else {
            currentCount = 1;
            restDaysRemaining = (restDaysRemaining - missedDays) > 0 ? (restDaysRemaining - missedDays) : 0;
          }
        }
      }
      prevDate = date;
    }

    final currentDate = now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    if (currentDate.month != currentMonth) {
      currentMonth = currentDate.month;
      restDaysRemaining = restDaysLimit;
    }

    if (prevDate != null) {
      final finalDiff = currentDate.difference(prevDate).inDays;
      if (finalDiff > 1) {
        final missedDays = finalDiff - 1;
        if (missedDays > restDaysRemaining) {
          currentCount = 0;
        } else {
          // Streak is still alive but we haven't run today, so count remains the same
          restDaysRemaining -= missedDays;
        }
      }
    } else {
      currentCount = 0;
    }

    return WeeklySummary(
      distanceKm: totalDistance,
      runCount: runCount,
      streakDays: currentCount,
      chartData: chartData,
      mostRecentRun: allRuns.first,
    );
  });
});


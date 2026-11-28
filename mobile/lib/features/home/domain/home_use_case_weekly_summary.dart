import '../../goals/domain/goals_use_case_calculate_progress.dart';

typedef WeeklySummary = ({
  double distanceKm,
  int runCount,
  int streakDays,
  List<double> chartData,
});

WeeklySummary calculateWeeklySummary(
  List<GoalActivity> allRuns, {
  required DateTime now,
  required int restDaysLimit,
  required String dailyMetric,
  required double dailyTarget,
}) {
  if (allRuns.isEmpty) {
    return (
      distanceKm: 0.0,
      runCount: 0,
      streakDays: 0,
      chartData: List.filled(7, 0.0),
    );
  }

  final startOfWeek = now
      .subtract(Duration(days: now.weekday - 1))
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  double totalDistance = 0;
  int runCount = 0;
  List<double> chartData = List.filled(7, 0.0);

  for (final run in allRuns) {
    if (run.startedAt != null && !run.startedAt!.isBefore(startOfWeek)) {
      runCount++;
      final distKm = run.distanceMeters / 1000.0;
      totalDistance += distKm;
      final dayIndex = run.startedAt!.weekday - 1;
      chartData[dayIndex] += distKm;
    }
  }

  final Map<DateTime, double> dailyAggregates = {};
  for (final run in allRuns) {
    if (run.startedAt != null) {
      final date = run.startedAt!.copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
      double value = 0.0;
      if (dailyMetric == 'steps') {
        value = run.steps.toDouble();
      } else if (dailyMetric == 'distance') {
        value = run.distanceMeters / 1000.0;
      } else if (dailyMetric == 'duration') {
        value = run.durationSeconds / 60.0;
      }
      dailyAggregates[date] = (dailyAggregates[date] ?? 0.0) + value;
    }
  }

  final runDays = <DateTime>{};
  for (final entry in dailyAggregates.entries) {
    if (entry.value >= dailyTarget) {
      runDays.add(entry.key);
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
          currentCount += missedDays + 1;
        } else {
          currentCount = 1;
          restDaysRemaining = (restDaysRemaining - missedDays) > 0
              ? (restDaysRemaining - missedDays)
              : 0;
        }
      }
    }
    prevDate = date;
  }

  final currentDate = now.copyWith(
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
    microsecond: 0,
  );
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
        // Streak is still alive but we haven't run today, so add the rest days to the streak
        restDaysRemaining -= missedDays;
        currentCount += missedDays;
      }
    }
  } else {
    currentCount = 0;
  }

  return (
    distanceKm: totalDistance,
    runCount: runCount,
    streakDays: currentCount,
    chartData: chartData,
  );
}

extension WeeklySummaryMetrics on WeeklySummary {
  int get activeDays => chartData.where((distance) => distance > 0).length;
  double distanceForUnit(bool useMiles) => useMiles ? distanceKm * 0.621371 : distanceKm;
  double averageDistance(bool useMiles) => runCount == 0 ? 0 : distanceForUnit(useMiles) / runCount;
}

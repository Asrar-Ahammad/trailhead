import 'dart:math' as math;

typedef GoalMetrics = ({String daily, String monthly});
typedef GoalActivity = ({
  DateTime? startedAt,
  int steps,
  double distanceMeters,
  int durationSeconds,
});
typedef GoalProgressData = ({double dailyProgress, double monthlyProgress});

GoalProgressData calculateGoalProgress({
  required Iterable<GoalActivity> activities,
  required GoalMetrics metrics,
  required DateTime now,
  int dailySteps = 0,
}) {
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month);
  var daily = 0.0;
  var monthly = 0.0;
  for (final activity in activities) {
    final date = activity.startedAt;
    if (date == null || date.isBefore(startOfMonth)) continue;
    if (!date.isBefore(startOfDay)) daily += _value(activity, metrics.daily);
    if (metrics.monthly != 'steps') {
      monthly += _value(activity, metrics.monthly);
    }
  }

  if (metrics.daily == 'steps') daily = math.max(daily, dailySteps.toDouble());
  return (dailyProgress: daily, monthlyProgress: monthly);
}

double _value(GoalActivity activity, String metric) => switch (metric) {
  'steps' => activity.steps.toDouble(),
  'distance' => activity.distanceMeters / 1000,
  'duration' => activity.durationSeconds / 60,
  _ => 0,
};

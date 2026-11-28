import 'dart:math' as math;

typedef HourlyActivitySteps = ({int hour, int steps});
typedef DailyStepsSummary = ({
  List<double> hours,
  double maxSteps,
  int totalSteps,
});

DailyStepsSummary summarizeDailySteps({
  required int backgroundTotal,
  required List<int> backgroundHours,
  required Iterable<HourlyActivitySteps> activities,
}) {
  final hours = backgroundHours.length == 24
      ? backgroundHours.map((steps) => steps.toDouble()).toList()
      : List<double>.filled(24, 0);
  var total = backgroundTotal;
  for (final activity in activities) {
    hours[activity.hour] += activity.steps;
    total += activity.steps;
  }
  final peak = hours.reduce(math.max);
  return (hours: hours, maxSteps: peak > 0 ? peak : 1000, totalSteps: total);
}

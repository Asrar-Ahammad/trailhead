typedef IsoWeek = ({int year, int number});
typedef WeeklyActivity = ({
  DateTime start,
  double distance,
  int duration,
  double calories,
  int steps,
  bool walk,
  double pace,
  double cadence,
  double stride,
});

IsoWeek isoWeekFor(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final first = DateTime.utc(thursday.year, 1, 1);
  return (
    year: thursday.year,
    number: thursday.difference(first).inDays ~/ 7 + 1,
  );
}

DateTime startOfIsoWeek(IsoWeek week) {
  final januaryFourth = DateTime(week.year, 1, 4);
  return DateTime(
    week.year,
    1,
    4 - (januaryFourth.weekday - 1) + (week.number - 1) * 7,
  );
}

class WeeklyTotals {
  WeeklyTotals(List<WeeklyActivity> activities)
    : distance = activities.fold(0.0, (sum, run) => sum + run.distance),
      duration = activities.fold(0, (sum, run) => sum + run.duration),
      calories = activities.fold(0.0, (sum, run) => sum + run.calories),
      steps = activities.fold(0, (sum, run) => sum + run.steps),
      walks = activities.where((run) => run.walk).length,
      count = activities.length,
      pace = _average(activities.map((run) => run.pace)),
      cadence = _average(activities.map((run) => run.cadence)),
      stride = _average(activities.map((run) => run.stride));

  final double distance, calories, pace, cadence, stride;
  final int duration, steps, walks, count;

  static double _average(Iterable<double> values) {
    final measured = values.where((value) => value > 0).toList();
    return measured.isEmpty
        ? 0
        : measured.reduce((a, b) => a + b) / measured.length;
  }
}

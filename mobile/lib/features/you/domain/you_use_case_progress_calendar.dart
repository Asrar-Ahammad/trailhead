typedef ProgressActivity = ({DateTime? date, double distanceM});

DateTime startOfProgressWindow(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1 - 77);

List<double> weeklyProgress(
  Iterable<ProgressActivity> activities,
  DateTime now,
) {
  final start = startOfProgressWindow(now);
  final calendarStart = DateTime.utc(start.year, start.month, start.day);
  final totals = List<double>.filled(12, 0);
  for (final activity in activities) {
    final date = activity.date;
    if (date == null) continue;
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(calendarStart).inDays;
    if (days >= 0 && days < 84) totals[days ~/ 7] += activity.distanceM / 1000;
  }
  return totals;
}

Map<int, List<T>> activitiesByMonthDay<T>(
  Iterable<T> activities,
  DateTime month,
  DateTime? Function(T) dateOf,
) {
  final days = <int, List<T>>{};
  for (final activity in activities) {
    final date = dateOf(activity);
    if (date?.year == month.year && date?.month == month.month) {
      days.putIfAbsent(date!.day, () => []).add(activity);
    }
  }
  return days;
}

import 'package:isar/isar.dart';

part 'daily_steps_isar.g.dart';

@collection
class DailyStepsIsar {
  Id id = Isar.autoIncrement;

  /// Date key in "YYYY-MM-DD" format, unique per day
  @Index(unique: true)
  String? dateKey;

  /// Total background steps recorded for this day
  int steps = 0;

  /// Last raw pedometer value seen (for delta calculation across app restarts)
  int lastPedometerValue = 0;

  /// Timestamp of the last update
  DateTime? lastUpdated;
}

import 'package:isar/isar.dart';
import 'models/daily_steps_isar.dart';

class DailyStepsRepository {
  DailyStepsRepository(this.isar);
  final Isar isar;

  Stream<DailyStepsIsar?> watch(DateTime date) {
    final key = date.toIso8601String().split('T').first;
    return isar.dailyStepsIsars
        .filter()
        .dateKeyEqualTo(key)
        .watch(fireImmediately: true)
        .map((records) => records.firstOrNull);
  }
}

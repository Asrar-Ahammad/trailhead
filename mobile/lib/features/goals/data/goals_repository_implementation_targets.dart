import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/goals_repository_targets.dart';
import 'models/goal_isar.dart';

class GoalsRepositoryImplementation implements GoalsRepository {
  GoalsRepositoryImplementation(this.isar, this.preferences);
  final Isar isar;
  final SharedPreferences preferences;

  @override
  Future<Goals> load() async {
    final dailyMetric = preferences.getString('dailyGoalMetric');
    final dailyTarget = preferences.getDouble('dailyGoalTarget');
    final monthlyMetric = preferences.getString('monthlyGoalMetric');
    final monthlyTarget = preferences.getDouble('monthlyGoalTarget');
    if (dailyMetric != null &&
        dailyTarget != null &&
        monthlyMetric != null &&
        monthlyTarget != null) {
      final stored = Goals(
        dailyGoalMetric: dailyMetric,
        dailyGoalTarget: dailyTarget,
        monthlyGoalMetric: monthlyMetric,
        monthlyGoalTarget: monthlyTarget,
      );
      final normalized = stored.normalizeLegacyMonthlyGoal();
      if (!identical(normalized, stored)) await _writePreferences(normalized);
      return normalized;
    }
    final row = await isar.goalIsars.getByKey('user_goals');
    if (row == null) return const Goals.empty();
    final goals = Goals(
      dailyGoalMetric: row.dailyGoalMetric,
      dailyGoalTarget: row.dailyGoalTarget,
      monthlyGoalMetric: row.monthlyGoalMetric,
      monthlyGoalTarget: row.monthlyGoalTarget,
    ).normalizeLegacyMonthlyGoal();
    await _writePreferences(goals);
    return goals;
  }

  @override
  Future<void> save(Goals goals) async {
    final previous = await load();
    try {
      await _writePreferences(goals);
      await isar.writeTxn(() async {
        await isar.goalIsars.putByKey(
          GoalIsar()
            ..dailyGoalMetric = goals.dailyGoalMetric
            ..dailyGoalTarget = goals.dailyGoalTarget
            ..monthlyGoalMetric = goals.monthlyGoalMetric
            ..monthlyGoalTarget = goals.monthlyGoalTarget,
        );
      });
    } catch (_) {
      await _writePreferences(previous);
      rethrow;
    }
  }

  Future<void> _writePreferences(Goals goals) async {
    final results = await Future.wait([
      preferences.setString('dailyGoalMetric', goals.dailyGoalMetric),
      preferences.setDouble('dailyGoalTarget', goals.dailyGoalTarget),
      preferences.setString('monthlyGoalMetric', goals.monthlyGoalMetric),
      preferences.setDouble('monthlyGoalTarget', goals.monthlyGoalTarget),
    ]);
    if (results.contains(false))
      throw StateError('Could not persist goal targets.');
  }
}

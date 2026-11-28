import 'package:isar/isar.dart';

import '../../run_tracking/data/models/daily_steps_isar.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../domain/goals_use_case_calculate_progress.dart';

class IsarGoalProgressRepository implements GoalProgressRepository {
  IsarGoalProgressRepository(this.isar);
  final Isar isar;

  @override
  Stream<GoalProgressData> watch(GoalMetrics metrics) {
    final changes = Stream<void>.multi((controller) {
      final runs = isar.runIsars.watchLazy().listen(
        (_) => controller.add(null),
        onError: controller.addError,
      );
      final steps = metrics.daily == 'steps'
          ? isar.dailyStepsIsars.watchLazy().listen(
              (_) => controller.add(null),
              onError: controller.addError,
            )
          : null;
      controller.onCancel = () async {
        await runs.cancel();
        await steps?.cancel();
      };
      controller.add(null);
    });
    return changes.asyncMap((_) => _readProgress(metrics));
  }

  Future<GoalProgressData> _readProgress(GoalMetrics metrics) async {
    final now = DateTime.now();
    final dateKey = now.toIso8601String().split('T').first;
    final runs = await isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .startTimeGreaterThan(DateTime(now.year, now.month), include: true)
        .findAll();
    final steps = metrics.daily == 'steps'
        ? await isar.dailyStepsIsars
              .filter()
              .dateKeyEqualTo(dateKey)
              .findFirst()
        : null;
    return calculateGoalProgress(
      activities: runs.map(
        (run) => (
          startedAt: run.startTime,
          steps: run.stepCount ?? 0,
          distanceMeters: run.distanceM ?? 0,
          durationSeconds: run.durationS ?? 0,
        ),
      ),
      metrics: metrics,
      now: now,
      dailySteps: steps?.steps ?? 0,
    );
  }
}

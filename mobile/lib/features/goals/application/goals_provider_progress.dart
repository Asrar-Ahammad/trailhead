import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../main.dart' show isarInstance;
import '../../run_tracking/data/models/daily_steps_isar.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../domain/goals_use_case_calculate_progress.dart';

final goalProgressProvider = StreamProvider.autoDispose
    .family<GoalProgressData, GoalMetrics>((ref, metrics) async* {
      final query = isarInstance.runIsars
          .filter()
          .statusEqualTo('completed')
          .build();
      await for (final runs in query.watch(fireImmediately: true)) {
        final now = DateTime.now();
        final dateKey = now.toIso8601String().split('T').first;
        final steps = metrics.daily == 'steps'
            ? await isarInstance.dailyStepsIsars
                  .filter()
                  .dateKeyEqualTo(dateKey)
                  .findFirst()
            : null;
        yield calculateGoalProgress(
          activities: runs.map(
            (run) => (
              startedAt: run.startTime,
              steps: run.stepCount ?? 0,
              distanceMeters: run.distanceM ?? 0.0,
              durationSeconds: run.durationS ?? 0,
            ),
          ),
          metrics: metrics,
          now: now,
          dailySteps: steps?.steps ?? 0,
        );
      }
    });

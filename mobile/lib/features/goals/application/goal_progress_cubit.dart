import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../shared/state/app_cubits.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/daily_steps_isar.dart';
import 'goals_cubit.dart';

class GoalProgressData {
  final double dailyProgress;
  final double monthlyProgress;

  GoalProgressData(this.dailyProgress, this.monthlyProgress);
}

class GoalProgressCubit extends Cubit<GoalProgressData> {
  GoalProgressCubit({required Isar isar, required GoalsCubit goalsCubit})
    : _isar = isar,
      _goalsCubit = goalsCubit,
      super(GoalProgressData(0, 0)) {
    _goalsSubscription = goalsCubit.stream.listen((_) => _refresh());
    _runsSubscription = _isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .build()
        .watch(fireImmediately: true)
        .listen((runs) {
          _runs = runs;
          _refresh();
        });
  }

  final Isar _isar;
  final GoalsCubit _goalsCubit;
  StreamSubscription<GoalsState>? _goalsSubscription;
  StreamSubscription<List<RunIsar>>? _runsSubscription;
  List<RunIsar> _runs = const [];

  Future<void> _refresh() async {
    if (isClosed) return;
    final goals = _goalsCubit.state.valueOrNull ?? Goals.empty();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    double dailyTotal = 0;
    double monthlyTotal = 0;
    for (final run in _runs) {
      if (run.startTime == null) continue;
      final date = run.startTime!;
      final isToday =
          date.isAfter(startOfDay) || date.isAtSameMomentAs(startOfDay);
      final isThisMonth =
          date.isAfter(startOfMonth) || date.isAtSameMomentAs(startOfMonth);
      if (!isThisMonth) continue;

      final dailyVal = switch (goals.dailyGoalMetric) {
        'steps' => (run.stepCount ?? 0).toDouble(),
        'distance' => (run.distanceM ?? 0) / 1000.0,
        'duration' => (run.durationS ?? 0) / 60.0,
        _ => 0.0,
      };
      final monthlyVal = switch (goals.monthlyGoalMetric) {
        'steps' => (run.stepCount ?? 0).toDouble(),
        'distance' => (run.distanceM ?? 0) / 1000.0,
        'duration' => (run.durationS ?? 0) / 60.0,
        _ => 0.0,
      };
      if (isToday) dailyTotal += dailyVal;
      monthlyTotal += monthlyVal;
    }

    if (goals.dailyGoalMetric == 'steps') {
      final todayRecord = await _isar.dailyStepsIsars
          .filter()
          .dateKeyEqualTo(todayKey)
          .findFirst();
      if (todayRecord != null) dailyTotal += todayRecord.steps.toDouble();
    }
    if (goals.monthlyGoalMetric == 'steps') {
      final monthStartKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextMonthKey =
          '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';
      final allMonthSteps = await _isar.dailyStepsIsars
          .filter()
          .dateKeyGreaterThan(monthStartKey, include: true)
          .and()
          .dateKeyLessThan(nextMonthKey)
          .findAll();
      for (final record in allMonthSteps) {
        monthlyTotal += record.steps.toDouble();
      }
    }
    if (!isClosed) emit(GoalProgressData(dailyTotal, monthlyTotal));
  }

  @override
  Future<void> close() async {
    await _goalsSubscription?.cancel();
    await _runsSubscription?.cancel();
    await super.close();
  }
}

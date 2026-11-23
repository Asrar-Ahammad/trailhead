import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart'; // import global isarInstance
import '../data/models/goal_isar.dart';

class Goals {
  final String dailyGoalMetric; // 'steps', 'distance', 'duration'
  final double dailyGoalTarget;
  final String monthlyGoalMetric;
  final double monthlyGoalTarget;

  Goals({
    required this.dailyGoalMetric,
    required this.dailyGoalTarget,
    required this.monthlyGoalMetric,
    required this.monthlyGoalTarget,
  });

  factory Goals.empty() {
    return Goals(
      dailyGoalMetric: 'steps',
      dailyGoalTarget: 5000,
      monthlyGoalMetric: 'distance',
      monthlyGoalTarget: 50,
    );
  }
}

class GoalsNotifier extends StateNotifier<AsyncValue<Goals>> {
  final Isar _isar;

  GoalsNotifier(this._isar) : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load local SharedPreferences cache first
      final dMetric = prefs.getString('dailyGoalMetric');
      final dTarget = prefs.getDouble('dailyGoalTarget');
      final mMetric = prefs.getString('monthlyGoalMetric');
      final mTarget = prefs.getDouble('monthlyGoalTarget');

      if (dMetric != null && dTarget != null && mMetric != null && mTarget != null) {
        final cleanMMetric = mMetric == 'steps' ? 'distance' : mMetric;
        final cleanMTarget = mMetric == 'steps' ? 50.0 : mTarget;
        final goals = Goals(
          dailyGoalMetric: dMetric,
          dailyGoalTarget: dTarget,
          monthlyGoalMetric: cleanMMetric,
          monthlyGoalTarget: cleanMTarget,
        );
        if (mMetric == 'steps') {
          await _saveToPrefs(goals, prefs);
        }
        state = AsyncValue.data(goals);
      } else {
        // Try loading from Isar
        final goalIsar = await _isar.goalIsars.filter().keyEqualTo('user_goals').findFirst();
        if (goalIsar != null) {
          final cleanMMetric = goalIsar.monthlyGoalMetric == 'steps' ? 'distance' : goalIsar.monthlyGoalMetric;
          final cleanMTarget = goalIsar.monthlyGoalMetric == 'steps' ? 50.0 : goalIsar.monthlyGoalTarget;
          final goals = Goals(
            dailyGoalMetric: goalIsar.dailyGoalMetric,
            dailyGoalTarget: goalIsar.dailyGoalTarget,
            monthlyGoalMetric: cleanMMetric,
            monthlyGoalTarget: cleanMTarget,
          );
          await _saveToPrefs(goals, prefs);
          state = AsyncValue.data(goals);
        } else {
          state = AsyncValue.data(Goals.empty());
        }
      }
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> _saveToPrefs(Goals goals, SharedPreferences prefs) async {
    await prefs.setString('dailyGoalMetric', goals.dailyGoalMetric);
    await prefs.setDouble('dailyGoalTarget', goals.dailyGoalTarget);
    await prefs.setString('monthlyGoalMetric', goals.monthlyGoalMetric);
    await prefs.setDouble('monthlyGoalTarget', goals.monthlyGoalTarget);
  }

  Future<void> saveGoals(Goals newGoals) async {
    try {
      state = const AsyncValue.loading();
      
      // Save to Isar
      await _isar.writeTxn(() async {
        var goalIsar = await _isar.goalIsars.filter().keyEqualTo('user_goals').findFirst();
        if (goalIsar == null) {
          goalIsar = GoalIsar();
        }
        goalIsar
          ..dailyGoalMetric = newGoals.dailyGoalMetric
          ..dailyGoalTarget = newGoals.dailyGoalTarget
          ..monthlyGoalMetric = newGoals.monthlyGoalMetric
          ..monthlyGoalTarget = newGoals.monthlyGoalTarget;
        await _isar.goalIsars.put(goalIsar);
      });

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await _saveToPrefs(newGoals, prefs);
      state = AsyncValue.data(newGoals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<Goals>>((ref) {
  return GoalsNotifier(isarInstance);
});

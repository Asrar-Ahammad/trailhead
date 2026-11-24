import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/goal_isar.dart';
import '../../../shared/state_management/async_value.dart';

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

class GoalsCubit extends Cubit<AsyncValue<Goals>> {
  final Isar _isar;
  final SharedPreferences _preferences;

  GoalsCubit({required Isar isar, required SharedPreferences preferences})
      : _isar = isar,
        _preferences = preferences,
        super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      // Load local SharedPreferences cache first
      final dMetric = _preferences.getString('dailyGoalMetric');
      final dTarget = _preferences.getDouble('dailyGoalTarget');
      final mMetric = _preferences.getString('monthlyGoalMetric');
      final mTarget = _preferences.getDouble('monthlyGoalTarget');

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
          await _saveToPrefs(goals);
        }
        emit(AsyncValue.data(goals));
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
          await _saveToPrefs(goals);
          emit(AsyncValue.data(goals));
        } else {
          emit(AsyncValue.data(Goals.empty()));
        }
      }
    } catch (e, st) {
      if (!state.hasValue) {
        emit(AsyncValue.error(e, st));
      }
    }
  }

  Future<void> _saveToPrefs(Goals goals) async {
    await _preferences.setString('dailyGoalMetric', goals.dailyGoalMetric);
    await _preferences.setDouble('dailyGoalTarget', goals.dailyGoalTarget);
    await _preferences.setString('monthlyGoalMetric', goals.monthlyGoalMetric);
    await _preferences.setDouble('monthlyGoalTarget', goals.monthlyGoalTarget);
  }

  Future<void> saveGoals(Goals newGoals) async {
    try {
      emit(const AsyncValue.loading());
      
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
      await _saveToPrefs(newGoals);
      emit(AsyncValue.data(newGoals));
    } catch (e, st) {
      emit(AsyncValue.error(e, st));
    }
  }
}

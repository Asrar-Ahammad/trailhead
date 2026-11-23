import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../sync/data/api_client.dart';

class Goals {
  const Goals({
    required this.dailyGoalMetric,
    required this.dailyGoalTarget,
    required this.monthlyGoalMetric,
    required this.monthlyGoalTarget,
  });

  final String dailyGoalMetric;
  final double dailyGoalTarget;
  final String monthlyGoalMetric;
  final double monthlyGoalTarget;

  factory Goals.empty() => const Goals(
    dailyGoalMetric: 'steps',
    dailyGoalTarget: 5000,
    monthlyGoalMetric: 'steps',
    monthlyGoalTarget: 150000,
  );
}

enum GoalsStatus { loading, loaded, error }

class GoalsState {
  const GoalsState._(this.status, {this.value, this.error, this.stackTrace});

  const GoalsState.loading() : this._(GoalsStatus.loading);
  const GoalsState.loaded(Goals goals)
    : this._(GoalsStatus.loaded, value: goals);
  const GoalsState.error(Object error, StackTrace stackTrace)
    : this._(GoalsStatus.error, error: error, stackTrace: stackTrace);

  final GoalsStatus status;
  final Goals? value;
  final Object? error;
  final StackTrace? stackTrace;
  Goals? get valueOrNull => value;
}

class GoalsCubit extends Cubit<GoalsState> {
  GoalsCubit({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(const GoalsState.loading()) {
    loadGoals();
  }

  final ApiClient _apiClient;

  Future<void> loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyMetric = prefs.getString('dailyGoalMetric');
      final dailyTarget = prefs.getDouble('dailyGoalTarget');
      final monthlyMetric = prefs.getString('monthlyGoalMetric');
      final monthlyTarget = prefs.getDouble('monthlyGoalTarget');

      if (dailyMetric != null &&
          dailyTarget != null &&
          monthlyMetric != null &&
          monthlyTarget != null) {
        emit(
          GoalsState.loaded(
            Goals(
              dailyGoalMetric: dailyMetric,
              dailyGoalTarget: dailyTarget,
              monthlyGoalMetric: monthlyMetric,
              monthlyGoalTarget: monthlyTarget,
            ),
          ),
        );
      } else {
        emit(GoalsState.loaded(Goals.empty()));
      }

      final response = await _apiClient.client.get('/auth/me');
      if (response.statusCode != 200) return;
      final data = response.data;
      final apiDailyMetric = data['dailyGoalMetric'] as String?;
      final apiDailyTarget = (data['dailyGoalTarget'] as num?)?.toDouble();
      final apiMonthlyMetric = data['monthlyGoalMetric'] as String?;
      final apiMonthlyTarget = (data['monthlyGoalTarget'] as num?)?.toDouble();
      if (apiDailyMetric == null ||
          apiDailyTarget == null ||
          apiMonthlyMetric == null ||
          apiMonthlyTarget == null)
        return;

      final goals = Goals(
        dailyGoalMetric: apiDailyMetric,
        dailyGoalTarget: apiDailyTarget,
        monthlyGoalMetric: apiMonthlyMetric,
        monthlyGoalTarget: apiMonthlyTarget,
      );
      await _saveToLocal(goals, prefs);
      if (!isClosed) emit(GoalsState.loaded(goals));
    } catch (error, stackTrace) {
      if (state.value == null && !isClosed) {
        emit(GoalsState.error(error, stackTrace));
      }
    }
  }

  Future<void> _saveToLocal(Goals goals, SharedPreferences prefs) async {
    await prefs.setString('dailyGoalMetric', goals.dailyGoalMetric);
    await prefs.setDouble('dailyGoalTarget', goals.dailyGoalTarget);
    await prefs.setString('monthlyGoalMetric', goals.monthlyGoalMetric);
    await prefs.setDouble('monthlyGoalTarget', goals.monthlyGoalTarget);
  }

  Future<void> saveGoals(Goals goals) async {
    emit(const GoalsState.loading());
    try {
      final response = await _apiClient.client.put(
        '/auth/me',
        data: {
          'dailyGoalMetric': goals.dailyGoalMetric,
          'dailyGoalTarget': goals.dailyGoalTarget,
          'monthlyGoalMetric': goals.monthlyGoalMetric,
          'monthlyGoalTarget': goals.monthlyGoalTarget,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to save goals');
      }
      final prefs = await SharedPreferences.getInstance();
      await _saveToLocal(goals, prefs);
      emit(GoalsState.loaded(goals));
    } catch (error, stackTrace) {
      emit(GoalsState.error(error, stackTrace));
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../sync/data/api_client.dart';

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
      monthlyGoalMetric: 'steps',
      monthlyGoalTarget: 150000,
    );
  }
}

class GoalsNotifier extends StateNotifier<AsyncValue<Goals>> {
  final ApiClient apiClient;

  GoalsNotifier({required this.apiClient}) : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load local cache first
      final dMetric = prefs.getString('dailyGoalMetric');
      final dTarget = prefs.getDouble('dailyGoalTarget');
      final mMetric = prefs.getString('monthlyGoalMetric');
      final mTarget = prefs.getDouble('monthlyGoalTarget');

      if (dMetric != null && dTarget != null && mMetric != null && mTarget != null) {
        state = AsyncValue.data(Goals(
          dailyGoalMetric: dMetric,
          dailyGoalTarget: dTarget,
          monthlyGoalMetric: mMetric,
          monthlyGoalTarget: mTarget,
        ));
      } else {
        state = AsyncValue.data(Goals.empty());
      }

      // Fetch from API
      final response = await apiClient.client.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        
        final dailyMetric = data['dailyGoalMetric'] as String?;
        final dailyTarget = (data['dailyGoalTarget'] as num?)?.toDouble();
        final monthlyMetric = data['monthlyGoalMetric'] as String?;
        final monthlyTarget = (data['monthlyGoalTarget'] as num?)?.toDouble();

        if (dailyMetric != null && dailyTarget != null && monthlyMetric != null && monthlyTarget != null) {
          final goals = Goals(
            dailyGoalMetric: dailyMetric,
            dailyGoalTarget: dailyTarget,
            monthlyGoalMetric: monthlyMetric,
            monthlyGoalTarget: monthlyTarget,
          );
          
          await _saveToLocal(goals, prefs);
          if (mounted) {
            state = AsyncValue.data(goals);
          }
        }
      }
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> _saveToLocal(Goals goals, SharedPreferences prefs) async {
    await prefs.setString('dailyGoalMetric', goals.dailyGoalMetric);
    await prefs.setDouble('dailyGoalTarget', goals.dailyGoalTarget);
    await prefs.setString('monthlyGoalMetric', goals.monthlyGoalMetric);
    await prefs.setDouble('monthlyGoalTarget', goals.monthlyGoalTarget);
  }

  Future<void> saveGoals(Goals newGoals) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await apiClient.client.put('/auth/me', data: {
        'dailyGoalMetric': newGoals.dailyGoalMetric,
        'dailyGoalTarget': newGoals.dailyGoalTarget,
        'monthlyGoalMetric': newGoals.monthlyGoalMetric,
        'monthlyGoalTarget': newGoals.monthlyGoalTarget,
      });

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await _saveToLocal(newGoals, prefs);
        state = AsyncValue.data(newGoals);
      } else {
        throw Exception('Failed to save goals');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<Goals>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return GoalsNotifier(apiClient: apiClient);
});

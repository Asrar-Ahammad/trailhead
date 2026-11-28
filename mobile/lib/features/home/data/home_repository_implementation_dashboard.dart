import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../history/data/run_history_repository.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../stats/application/ai_coach_service.dart';
import '../domain/home_use_case_weekly_summary.dart';

typedef HomeWeeklyData = ({WeeklySummary summary, RunIsar? mostRecentRun});

class HomeDashboardRepository {
  HomeDashboardRepository(this.history, this.preferences, this.coach);
  final RunHistoryRepository history;
  final SharedPreferences preferences;
  final AiCoachService coach;

  Stream<HomeWeeklyData> watchWeek() => history
      .watchCompletedRuns(limit: 500)
      .map(
        (runs) => (
          summary: calculateWeeklySummary(
            runs
                .map(
                  (run) => (
                    startedAt: run.startTime,
                    steps: run.stepCount ?? 0,
                    distanceMeters: run.distanceM ?? 0,
                    durationSeconds: run.durationS ?? 0,
                  ),
                )
                .toList(),
            now: DateTime.now(),
            restDaysLimit: preferences.getInt('rest_days_limit') ?? 0,
            dailyMetric: preferences.getString('dailyGoalMetric') ?? 'steps',
            dailyTarget: preferences.getDouble('dailyGoalTarget') ?? 5000,
          ),
          mostRecentRun: runs.firstOrNull,
        ),
      );

  Future<AiCoachData> loadCoach() => coach.loadCoachData();

  Future<String?> loadTrend() async {
    final cached = preferences.getString('user_performance_summary');
    if (cached == null) return null;
    return (jsonDecode(cached) as Map<String, dynamic>)['trendMessage']
        as String?;
  }
}

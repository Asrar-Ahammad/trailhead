import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../run_tracking/data/models/run_isar.dart';
import '../../../run_tracking/data/models/daily_steps_isar.dart';
import '../../../goals/application/goals_provider.dart';
import '../../../goals/presentation/set_goals_sheet.dart';
import '../../../haptics/application/haptics_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../main.dart'; // for isarInstance

class GoalProgressData {
  final double dailyProgress;
  final double monthlyProgress;
  
  GoalProgressData(this.dailyProgress, this.monthlyProgress);
}

final goalProgressProvider = StreamProvider.autoDispose<GoalProgressData>((ref) async* {
  final goalsAsync = ref.watch(goalsProvider);
  final goals = goalsAsync.valueOrNull ?? Goals.empty();
  
  // Watch all completed runs
  final query = isarInstance.runIsars.filter().statusEqualTo('completed').build();
  
  await for (final runs in query.watch(fireImmediately: true)) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    double dailyTotal = 0;
    double monthlyTotal = 0;
    
    for (final run in runs) {
      if (run.startTime == null) continue;
      
      final date = run.startTime!;
      final isToday = date.isAfter(startOfDay) || date.isAtSameMomentAs(startOfDay);
      final isThisMonth = date.isAfter(startOfMonth) || date.isAtSameMomentAs(startOfMonth);
      
      if (!isThisMonth) continue;
      
      double dailyVal = 0;
      double monthlyVal = 0;
      
      // Daily Metric
      if (goals.dailyGoalMetric == 'steps') {
        dailyVal = (run.stepCount ?? 0).toDouble();
      } else if (goals.dailyGoalMetric == 'distance') {
        dailyVal = (run.distanceM ?? 0) / 1000.0;
      } else if (goals.dailyGoalMetric == 'duration') {
        dailyVal = (run.durationS ?? 0) / 60.0;
      }
      
      // Monthly Metric
      if (goals.monthlyGoalMetric == 'steps') {
        monthlyVal = (run.stepCount ?? 0).toDouble();
      } else if (goals.monthlyGoalMetric == 'distance') {
        monthlyVal = (run.distanceM ?? 0) / 1000.0;
      } else if (goals.monthlyGoalMetric == 'duration') {
        monthlyVal = (run.durationS ?? 0) / 60.0;
      }
      
      if (isToday) dailyTotal += dailyVal;
      monthlyTotal += monthlyVal;
    }

    // Add background steps from DailyStepsIsar
    if (goals.dailyGoalMetric == 'steps') {
      final todayRecord = await isarInstance.dailyStepsIsars
          .filter()
          .dateKeyEqualTo(todayKey)
          .findFirst();
      if (todayRecord != null) {
        dailyTotal += todayRecord.steps.toDouble();
      }
    }

    if (goals.monthlyGoalMetric == 'steps') {
      // Sum background steps for the entire month
      final monthStartKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final allMonthSteps = await isarInstance.dailyStepsIsars
          .filter()
          .dateKeyGreaterThan(monthStartKey, include: true)
          .and()
          .dateKeyLessThan('${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-01')
          .findAll();
      for (final record in allMonthSteps) {
        monthlyTotal += record.steps.toDouble();
      }
    }
    
    yield GoalProgressData(dailyTotal, monthlyTotal);
  }
});

class GoalsProgressCard extends ConsumerWidget {
  final AppColors retroColors;
  
  const GoalsProgressCard({super.key, required this.retroColors});

  String _formatMetric(String metric, double value, double target) {
    if (metric == 'steps') {
      return '${value.toInt()} / ${target.toInt()}';
    } else if (metric == 'distance') {
      return '${value.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} km';
    } else {
      return '${value.toInt()} / ${target.toInt()} min';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final progressAsync = ref.watch(goalProgressProvider);
    
    final goals = goalsAsync.valueOrNull ?? Goals.empty();
    final progress = progressAsync.valueOrNull ?? GoalProgressData(0, 0);

    final dailyRatio = (goals.dailyGoalTarget > 0) ? (progress.dailyProgress / goals.dailyGoalTarget).clamp(0.0, 1.0) : 0.0;
    final monthlyRatio = (goals.monthlyGoalTarget > 0) ? (progress.monthlyProgress / goals.monthlyGoalTarget).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        ref.read(hapticsServiceProvider).lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: retroColors.surface,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SetGoalsSheet(retroColors: retroColors),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: retroColors.surfaceRaised,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: retroColors.border.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('YOUR GOALS', style: AppTextStyles.label(color: retroColors.accent)),
                Icon(Icons.settings, color: retroColors.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: AppTextStyles.bodyMediumBold(color: retroColors.textPrimary)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: dailyRatio,
                        backgroundColor: retroColors.surface,
                        color: retroColors.accent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMetric(goals.dailyGoalMetric, progress.dailyProgress, goals.dailyGoalTarget),
                        style: AppTextStyles.labelCaps(color: retroColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This Month', style: AppTextStyles.bodyMediumBold(color: retroColors.textPrimary)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: monthlyRatio,
                        backgroundColor: retroColors.surface,
                        color: retroColors.success,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMetric(goals.monthlyGoalMetric, progress.monthlyProgress, goals.monthlyGoalTarget),
                        style: AppTextStyles.labelCaps(color: retroColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

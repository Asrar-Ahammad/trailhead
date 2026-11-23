import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../goals/application/goals_cubit.dart';
import '../../../goals/application/goal_progress_cubit.dart';
import '../../../goals/presentation/set_goals_sheet.dart';
import '../../../haptics/application/haptics_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';

class GoalsProgressCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final goalsAsync = context.watch<GoalsCubit>().state;
    final progress = context.watch<GoalProgressCubit>().state;
    
    final goals = goalsAsync.valueOrNull ?? Goals.empty();

    final dailyRatio = (goals.dailyGoalTarget > 0) ? (progress.dailyProgress / goals.dailyGoalTarget).clamp(0.0, 1.0) : 0.0;
    final monthlyRatio = (goals.monthlyGoalTarget > 0) ? (progress.monthlyProgress / goals.monthlyGoalTarget).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        context.read<HapticsService>().lightImpact();
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

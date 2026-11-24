import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../run_tracking/data/models/run_isar.dart';
import '../../../run_tracking/data/models/daily_steps_isar.dart';
import '../../../goals/application/goals_cubit.dart';
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
  final goals = GetIt.instance<GoalsCubit>().state.valueOrNull ?? Goals.empty();
  
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
      
      // Monthly Metric (Distance or Duration only)
      if (goals.monthlyGoalMetric == 'distance') {
        monthlyVal = (run.distanceM ?? 0) / 1000.0;
      } else if (goals.monthlyGoalMetric == 'duration') {
        monthlyVal = (run.durationS ?? 0) / 60.0;
      }
      
      if (isToday) dailyTotal += dailyVal;
      monthlyTotal += monthlyVal;
    }

    // Adjust for steps double counting
    if (goals.dailyGoalMetric == 'steps') {
      final todayRecord = await isarInstance.dailyStepsIsars
          .filter()
          .dateKeyEqualTo(todayKey)
          .findFirst();
      if (todayRecord != null && todayRecord.steps.toDouble() > dailyTotal) {
        dailyTotal = todayRecord.steps.toDouble();
      }
    }

    yield GoalProgressData(dailyTotal, monthlyTotal);
  }
});

class GoalsProgressCard extends ConsumerWidget {
  final AppColors retroColors;
  
  const GoalsProgressCard({super.key, required this.retroColors});

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'steps':
        return PhosphorIcons.footprintsFill;
      case 'distance':
        return PhosphorIcons.personSimpleRun;
      case 'duration':
        return PhosphorIcons.timerFill;
      default:
        return PhosphorIcons.target;
    }
  }

  String _formatNumber(double val, String metric) {
    if (metric == 'steps') {
      return val.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } else if (metric == 'distance') {
      return val.toStringAsFixed(1);
    } else {
      return val.toInt().toString();
    }
  }

  String _getMetricUnit(String metric) {
    switch (metric) {
      case 'steps':
        return 'steps';
      case 'distance':
        return 'km';
      case 'duration':
        return 'min';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = context.watch<GoalsCubit>().state;
    final progressAsync = ref.watch(goalProgressProvider);
    
    final goals = goalsAsync.valueOrNull ?? Goals.empty();
    final progress = progressAsync.valueOrNull ?? GoalProgressData(0, 0);

    final dailyTarget = goals.dailyGoalTarget > 0 ? goals.dailyGoalTarget : 1.0;
    final dailyRatio = (progress.dailyProgress / dailyTarget).clamp(0.0, 1.0);
    final dailyPercent = (dailyRatio * 100).toInt();
    final isCompleted = dailyRatio >= 1.0;

    final showMonthly = goals.monthlyGoalMetric != 'steps' && goals.monthlyGoalTarget > 0;
    final monthlyTarget = goals.monthlyGoalTarget > 0 ? goals.monthlyGoalTarget : 1.0;
    final monthlyRatio = (progress.monthlyProgress / monthlyTarget).clamp(0.0, 1.0);

    final remainingVal = (goals.dailyGoalTarget - progress.dailyProgress).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: retroColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: retroColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: retroColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: retroColors.accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'TARGET // TODAY',
                            style: GoogleFonts.pixelifySans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: retroColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? retroColors.success.withValues(alpha: 0.15)
                                : retroColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? PhosphorIcons.checkCircleFill
                                    : PhosphorIcons.flameFill,
                                size: 13,
                                color: isCompleted ? retroColors.success : retroColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'REACHED' : '$dailyPercent%',
                                style: AppTextStyles.labelCaps(
                                  color: isCompleted ? retroColors.success : retroColors.accent,
                                ).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: retroColors.surfaceRaised,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.gearSix,
                            color: retroColors.textSecondary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Hero Numbers & Circular Arc Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: retroColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getMetricIcon(goals.dailyGoalMetric),
                              color: retroColors.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _formatNumber(progress.dailyProgress, goals.dailyGoalMetric),
                                        style: GoogleFonts.barlowCondensed(
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                          color: retroColors.textPrimary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${_formatNumber(goals.dailyGoalTarget, goals.dailyGoalTarget is int ? "steps" : goals.dailyGoalMetric)} ${_getMetricUnit(goals.dailyGoalMetric)}',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: retroColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCompleted
                                      ? 'Goal completed! Keep it rolling.'
                                      : '${_formatNumber(remainingVal, goals.dailyGoalMetric)} ${_getMetricUnit(goals.dailyGoalMetric)} remaining today',
                                  style: AppTextStyles.bodyMedium(
                                    color: isCompleted
                                        ? retroColors.success
                                        : retroColors.textSecondary,
                                  ).copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Styled Stadium Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        color: retroColors.surfaceRaised,
                      ),
                      FractionallySizedBox(
                        widthFactor: dailyRatio,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCompleted ? retroColors.success : retroColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Optional Monthly Distance Pill (only if configured)
                if (showMonthly) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: retroColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: retroColors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.chartLineUpFill,
                          color: retroColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'THIS MONTH',
                          style: AppTextStyles.labelCaps(color: retroColors.textSecondary).copyWith(fontSize: 10),
                        ),
                        const Spacer(),
                        Text(
                          '${_formatNumber(progress.monthlyProgress, goals.monthlyGoalMetric)} / ${_formatNumber(goals.monthlyGoalTarget, goals.monthlyGoalMetric)} ${_getMetricUnit(goals.monthlyGoalMetric)}',
                          style: AppTextStyles.bodyMediumBold(color: retroColors.textPrimary).copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: retroColors.surface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: monthlyRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: retroColors.accent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

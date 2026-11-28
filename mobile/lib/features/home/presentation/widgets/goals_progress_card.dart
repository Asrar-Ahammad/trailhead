import 'package:flutter/material.dart';
import '../../../../shared/navigation/app_navigator.dart';
import '../../../goals/domain/goals_repository_targets.dart';
import '../../../goals/domain/goals_use_case_calculate_progress.dart';
import '../../../goals/state_management/goals_bloc_progress.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../shared/state_management/global/goals_cubit_targets.dart';
import '../../../goals/presentation/set_goals_sheet.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';

class GoalsProgressCard extends StatelessWidget {
  final AppColors retroColors;

  const GoalsProgressCard({super.key, required this.retroColors});

  @override
  Widget build(BuildContext context) {
    final goals =
        context.watch<GoalsCubit>().state.valueOrNull ?? const Goals.empty();
    final metrics = (
      daily: goals.dailyGoalMetric,
      monthly: goals.monthlyGoalMetric,
    );
    return BlocProvider(
      key: ValueKey(metrics),
      create: (_) => context.read<CreateGoalProgressBloc>()(metrics),
      child: _GoalsProgressContent(retroColors, goals),
    );
  }
}

class _GoalsProgressContent extends StatelessWidget {
  const _GoalsProgressContent(this.retroColors, this.goals);
  final AppColors retroColors;
  final Goals goals;

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
  Widget build(BuildContext context) {
    final progress =
        context.watch<GoalProgressBloc>().state.valueOrNull ??
        (dailyProgress: 0.0, monthlyProgress: 0.0);
    final daily = GoalCompletion(progress.dailyProgress, goals.dailyGoalTarget);
    final monthly = GoalCompletion(
      progress.monthlyProgress,
      goals.monthlyGoalTarget,
    );
    final showMonthly =
        goals.monthlyGoalMetric != 'steps' && goals.monthlyGoalTarget > 0;

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
            context.read<HapticsCubit>().lightImpact();
            AppNavigator.bottomSheet(
              context,
              (_) => SetGoalsSheet(retroColors: retroColors),
              backgroundColor: retroColors.surface,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: daily.isComplete
                                ? retroColors.success.withValues(alpha: 0.15)
                                : retroColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                daily.isComplete
                                    ? PhosphorIcons.checkCircleFill
                                    : PhosphorIcons.flameFill,
                                size: 13,
                                color: daily.isComplete
                                    ? retroColors.success
                                    : retroColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daily.isComplete
                                    ? 'REACHED'
                                    : '${daily.percent}%',
                                style: AppTextStyles.labelCaps(
                                  color: daily.isComplete
                                      ? retroColors.success
                                      : retroColors.accent,
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
                                        text: _formatNumber(
                                          progress.dailyProgress,
                                          goals.dailyGoalMetric,
                                        ),
                                        style: GoogleFonts.barlowCondensed(
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                          color: retroColors.textPrimary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' / ${_formatNumber(goals.dailyGoalTarget, goals.dailyGoalMetric)} ${_getMetricUnit(goals.dailyGoalMetric)}',
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
                                  daily.isComplete
                                      ? 'Goal completed! Keep it rolling.'
                                      : '${_formatNumber(daily.remaining, goals.dailyGoalMetric)} ${_getMetricUnit(goals.dailyGoalMetric)} remaining today',
                                  style: AppTextStyles.bodyMedium(
                                    color: daily.isComplete
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
                        widthFactor: daily.ratio,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: daily.isComplete
                                ? retroColors.success
                                : retroColors.accent,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                          style: AppTextStyles.labelCaps(
                            color: retroColors.textSecondary,
                          ).copyWith(fontSize: 10),
                        ),
                        const Spacer(),
                        Text(
                          '${_formatNumber(progress.monthlyProgress, goals.monthlyGoalMetric)} / ${_formatNumber(goals.monthlyGoalTarget, goals.monthlyGoalMetric)} ${_getMetricUnit(goals.monthlyGoalMetric)}',
                          style: AppTextStyles.bodyMediumBold(
                            color: retroColors.textPrimary,
                          ).copyWith(fontSize: 12),
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
                            widthFactor: monthly.ratio,
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

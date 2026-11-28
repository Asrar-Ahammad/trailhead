import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/global/haptics_cubit_feedback.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import '../state_management/weather_bloc_pacing.dart';
import '../application/weather_utils.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';

class WeatherPaceCard extends StatelessWidget {
  const WeatherPaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final weatherAsync = context.watch<WeatherBloc>().state;
    final useMiles = context.watch<DistanceUnitCubit>().state;
    final targetPace = context.select(
      (RunTrackerCubit cubit) => cubit.state.targetPaceSPerKm,
    );

    return weatherAsync.when(
      data: (data) {
        final temp = data.conditions.temperature.round();
        final wind = data.conditions.windSpeed.round();
        final adjustmentSeconds = data.adjustmentSeconds;
        final baseAdjustedPaceS = data.adjustedPaceSeconds;
        final weatherCode = data.conditions.code;
        final isDay = data.conditions.isDay;
        final advice = data.advice;
        final paceDigits = data.displayPace(useMiles);
        final String unitLabel = useMiles ? '/ MI' : '/ KM';

        final bool isPaceApplied = targetPace == baseAdjustedPaceS;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header Row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'AI // PACING ADVISOR',
                      style: GoogleFonts.pixelifySans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: colors.accent,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          WeatherUtils.getWeatherIcon(
                            weatherCode,
                            isDay: isDay,
                          ),
                          color: WeatherUtils.getWeatherColor(
                            weatherCode,
                            colors,
                            isDay: isDay,
                          ),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$temp°C',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          PhosphorIcons.wind,
                          color: colors.textSecondary,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$wind km/h',
                          style: AppTextStyles.labelCaps(
                            color: colors.textSecondary,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Hero Recommended Pace Display
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          PhosphorIcons.timerFill,
                          color: colors.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                paceDigits,
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  letterSpacing: 0.5,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                unitLabel,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.accent,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'RECOMMENDED BASELINE',
                            style: AppTextStyles.labelCaps(
                              color: colors.textSecondary,
                            ).copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: adjustmentSeconds > 0
                          ? colors.warning.withValues(alpha: 0.15)
                          : colors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          adjustmentSeconds > 0
                              ? PhosphorIcons.warningCircleFill
                              : PhosphorIcons.checkCircleFill,
                          size: 13,
                          color: adjustmentSeconds > 0
                              ? colors.warning
                              : colors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          adjustmentSeconds > 0
                              ? '+${adjustmentSeconds}s LOAD'
                              : (adjustmentSeconds < 0
                                    ? '${adjustmentSeconds}s COOL'
                                    : 'OPTIMAL'),
                          style: AppTextStyles.labelCaps(
                            color: adjustmentSeconds > 0
                                ? colors.warning
                                : colors.success,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weather Impact Advice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        advice,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Interactive Target Pace Action
              GestureDetector(
                onTap: () {
                  context.read<HapticsCubit>().mediumImpact();
                  if (isPaceApplied) {
                    context.read<RunTrackerCubit>().setTargetPace(null);
                  } else {
                    context.read<RunTrackerCubit>().setTargetPace(
                      baseAdjustedPaceS,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isPaceApplied
                        ? colors.success.withValues(alpha: 0.12)
                        : colors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPaceApplied
                          ? colors.success.withValues(alpha: 0.3)
                          : colors.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPaceApplied
                            ? PhosphorIcons.checkCircleFill
                            : PhosphorIcons.target,
                        size: 15,
                        color: isPaceApplied ? colors.success : colors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPaceApplied
                            ? 'TARGET PACE APPLIED TO RUNNER'
                            : 'SET AS ACTIVE RUN TARGET PACE',
                        style: AppTextStyles.labelCaps(
                          color: isPaceApplied ? colors.success : colors.accent,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: RetroLoadingIndicator(text: 'ANALYZING WEATHER PACING'),
        ),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(PhosphorIcons.warningCircle, color: colors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Weather pacing requires location services enabled.',
                style: AppTextStyles.bodyMedium(
                  color: colors.textSecondary,
                ).copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

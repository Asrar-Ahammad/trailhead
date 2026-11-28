import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';
import 'dart:ui';
import 'package:trailhead_mobile/features/home/domain/home_use_case_weekly_summary.dart';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeWeeklySummary extends StatelessWidget {
  final WeeklySummary summary;
  final AppColors colors;
  final bool useMiles;

  const HomeWeeklySummary({
    required this.summary,
    required this.colors,
    required this.useMiles,
  });

  @override
  Widget build(BuildContext context) {
    final displayDistance = summary.distanceForUnit(useMiles);
    final unitStr = useMiles ? 'MI' : 'KM';
    final activeDaysCount = summary.activeDays;
    final avgPerRun = summary.averageDistance(useMiles);
    final todayWeekday = DateTime.now().weekday - 1; // 0 = Mon, 6 = Sun
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
          // Top Row: Badge + Streak
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'TRAIL // WEEKLY VOLUME',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.accent,
                  ),
                ),
              ),
              if (summary.streakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.flameFill,
                        color: colors.accent,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${summary.streakDays} DAY STREAK',
                          style: AppTextStyles.labelCaps(
                            color: colors.accent,
                          ).copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'WEEK TO DATE',
                    style: AppTextStyles.labelCaps(
                      color: colors.textSecondary,
                    ).copyWith(fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Hero Number & 7-Day Rhythm Capsules
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              // Big distance hero
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        displayDistance.toStringAsFixed(1),
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unitStr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.runCount == 0
                        ? 'No runs logged yet this week'
                        : '${summary.runCount} ${summary.runCount == 1 ? 'activity' : 'activities'} logged',
                    style: AppTextStyles.bodyMedium(
                      color: colors.textSecondary,
                    ).copyWith(fontSize: 13),
                  ),
                ],
              ),

              // 7-day mini weekday dots/bars
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  runSpacing: 6,
                  children: List.generate(7, (i) {
                    final hasRun = summary.chartData[i] > 0;
                    final isToday = i == todayWeekday;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 18,
                            decoration: BoxDecoration(
                              color: hasRun
                                  ? colors.accent
                                  : colors.textSecondary.withValues(
                                      alpha: 0.18,
                                    ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weekdays[i],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isToday
                                  ? (hasRun
                                        ? colors.accent
                                        : colors.textPrimary)
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Sub-metrics row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AdaptiveColumns(
              maxColumns: 3,
              minColumnWidth: 72,
              spacing: 8,
              children: [
                _buildSubMetric(
                  icon: PhosphorIcons.sneakerMove,
                  label: 'ACTIVITIES',
                  value: summary.runCount.toString(),
                  colors: colors,
                ),
                _buildSubMetric(
                  icon: PhosphorIcons.chartLineUp,
                  label: 'AVG / RUN',
                  value: '${avgPerRun.toStringAsFixed(1)} $unitStr',
                  colors: colors,
                ),
                _buildSubMetric(
                  icon: PhosphorIcons.calendarDots,
                  label: 'ACTIVE DAYS',
                  value: '$activeDaysCount / 7',
                  colors: colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, color: colors.accent, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelCaps(
                color: colors.textSecondary,
              ).copyWith(fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.barlowCondensed(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

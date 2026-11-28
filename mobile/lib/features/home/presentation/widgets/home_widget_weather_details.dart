import 'package:trailhead_mobile/shared/widgets/adaptive_columns.dart';
import 'package:trailhead_mobile/shared/widgets/inset_sheet_body.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trailhead_mobile/features/weather/domain/weather_use_case_pacing.dart';
import 'package:trailhead_mobile/features/weather/application/weather_utils.dart';

class HomeWeatherDetails extends StatelessWidget {
  final AppColors colors;
  final WeatherPacing data;

  const HomeWeatherDetails({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final temp = data.conditions.temperature.round();
    final wind = data.conditions.windSpeed.round();
    final advice = data.advice;
    final city = data.conditions.city;
    final isDay = data.conditions.isDay;
    final code = data.conditions.code;
    final weatherIcon = WeatherUtils.getWeatherIcon(code, isDay: isDay);
    final weatherColor = WeatherUtils.getWeatherColor(
      code,
      colors,
      isDay: isDay,
    );
    final weatherDesc = WeatherUtils.getWeatherDescription(code);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: isDark ? 0.88 : 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: InsetSheetBody(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: weatherColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: weatherColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              weatherIcon,
                              color: weatherColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weatherDesc.toUpperCase(),
                                  style: AppTextStyles.headline(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  city,
                                  style: AppTextStyles.label(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.x, color: colors.textSecondary),
                      onPressed: () => AppNavigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                AdaptiveColumns(
                  maxColumns: 2,
                  minColumnWidth: 124,
                  children: [
                    _weatherMetric('TEMPERATURE', '$temp°C'),
                    _weatherMetric('WIND SPEED', '$wind km/h'),
                  ],
                ),
                const SizedBox(height: 16),

                // Pacing Advice Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.lightningFill,
                        color: colors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COACH ADVICE',
                              style: AppTextStyles.labelCaps(
                                color: colors.accent,
                              ).copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              advice,
                              style: AppTextStyles.bodyMedium(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _weatherMetric(String label, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.surfaceRaised.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.border.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps(
            color: colors.textSecondary,
          ).copyWith(fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.barlowCondensed(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

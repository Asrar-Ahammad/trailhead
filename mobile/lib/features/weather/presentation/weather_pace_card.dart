import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/shared/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../application/weather_service.dart';
import 'package:trailhead_mobile/shared/widgets/retro_loading_indicator.dart';

class WeatherPaceCard extends ConsumerWidget {
  const WeatherPaceCard({super.key});

  IconData _getWeatherIcon(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return PhosphorIcons.sun();
    if (code >= 1 && code <= 3) return PhosphorIcons.cloudSun();
    if (code >= 45 && code <= 48) return PhosphorIcons.cloudFog();
    if (code >= 51 && code <= 67) return PhosphorIcons.cloudRain();
    if (code >= 71 && code <= 77) return PhosphorIcons.cloudSnow();
    if (code >= 95 && code <= 99) return PhosphorIcons.cloudLightning();
    return PhosphorIcons.cloud();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final weatherAsync = ref.watch(weatherPacingProvider);

    return weatherAsync.when(
      data: (data) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getWeatherIcon(data['weatherCode']), color: colors.accent, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text('${data['temperature']}°C', style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(PhosphorIcons.wind(), color: colors.textSecondary, size: 16),
                      const SizedBox(width: 4),
                      Text('${data['windSpeed']} km/h', style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('AI PACING', style: AppTextStyles.labelCaps(color: colors.accent)),
                  )
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('RECOMMENDED PACE', style: AppTextStyles.retroLabel(color: colors.textSecondary).copyWith(fontSize: 12)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(data['adjustedPace'], style: AppTextStyles.displayMedium(color: colors.accent)),
                  if (data['adjustmentSeconds'] > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text('(+${data['adjustmentSeconds']}s)', style: AppTextStyles.bodyMedium(color: colors.error)),
                  ] else if (data['adjustmentSeconds'] < 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text('(${data['adjustmentSeconds']}s)', style: AppTextStyles.bodyMedium(color: Colors.green)),
                  ]
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(data['advice'], style: AppTextStyles.bodyMedium(color: colors.textSecondary)),
            ],
          ),
        );
      },
      loading: () => const RetroLoadingIndicator(text: 'FETCHING WEATHER'),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(PhosphorIcons.warningCircle(), color: colors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Weather unavailable. Please allow location permissions.',
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

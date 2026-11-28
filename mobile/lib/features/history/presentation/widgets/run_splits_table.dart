import '../../domain/history_use_case_route_analytics.dart';
import '../../data/history_mapper_route_metrics.dart';
import 'package:flutter/material.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class RunSplitsTable extends StatelessWidget {
  final List<RunPointIsar> points;

  const RunSplitsTable({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final splits = calculateActivitySplits(
      points.map(toRouteMetricPoint).toList(),
    );

    if (splits.isEmpty) {
      return const SizedBox.shrink();
    }

    int minPace = splits.first.paceSPerKm;
    int maxPace = splits.first.paceSPerKm;
    for (var s in splits) {
      if (s.paceSPerKm < minPace) minPace = s.paceSPerKm;
      if (s.paceSPerKm > maxPace) maxPace = s.paceSPerKm;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Splits',
          style: AppTextStyles.headline(
            color: colors.textPrimary,
          ).copyWith(fontSize: 24),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                'Km',
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              ),
            ),
            SizedBox(
              width: 78,
              child: Text(
                'Pace',
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
            SizedBox(
              width: 56,
              child: Text(
                'Elev',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 16),
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: splits.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final split = splits[index];

            // Calculate bar width (faster pace = longer bar)
            double ratio = 1.0;
            if (maxPace > minPace) {
              ratio =
                  0.3 +
                  0.7 *
                      (1.0 -
                          (split.paceSPerKm - minPace) / (maxPace - minPace));
            } else {
              ratio = 0.8;
            }

            final paceMins = split.paceSPerKm ~/ 60;
            final paceSecs = split.paceSPerKm % 60;
            final paceStr = '$paceMins:${paceSecs.toString().padLeft(2, '0')}';

            return Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    split.kmLabel,
                    style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 78,
                  child: Text(
                    paceStr,
                    style: AppTextStyles.bodyMedium(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Container(
                            height: 18,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ), // Blue matching the mock
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${split.elevationChange}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium(color: colors.textPrimary),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';

class RunSplitsTable extends StatelessWidget {
  final List<RunPointIsar> points;

  const RunSplitsTable({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final splits = _calculateSplits();

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
        Text('Splits', style: AppTextStyles.headline(color: colors.textPrimary).copyWith(fontSize: 24)),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(width: 40, child: Text('Km', style: AppTextStyles.bodyMedium(color: colors.textSecondary))),
            SizedBox(width: 60, child: Text('Pace', style: AppTextStyles.bodyMedium(color: colors.textSecondary))),
            const Expanded(child: SizedBox.shrink()),
            SizedBox(width: 40, child: Text('Elev', textAlign: TextAlign.right, style: AppTextStyles.bodyMedium(color: colors.textSecondary))),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: splits.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final split = splits[index];
            
            // Calculate bar width (faster pace = longer bar)
            double ratio = 1.0;
            if (maxPace > minPace) {
              ratio = 0.3 + 0.7 * (1.0 - (split.paceSPerKm - minPace) / (maxPace - minPace));
            } else {
              ratio = 0.8;
            }

            final paceMins = split.paceSPerKm ~/ 60;
            final paceSecs = split.paceSPerKm % 60;
            final paceStr = '$paceMins:${paceSecs.toString().padLeft(2, '0')}';

            return Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    split.kmLabel,
                    style: AppTextStyles.bodyLarge(color: colors.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    paceStr,
                    style: AppTextStyles.bodyMedium(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Container(
                            height: 18,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6), // Blue matching the mock
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
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

  List<_SplitData> _calculateSplits() {
    if (points.isEmpty) return [];

    final distanceCalc = const Distance();
    final splits = <_SplitData>[];
    
    double accumulatedDistanceM = 0;
    int currentKm = 1;
    DateTime? splitStartTime;
    DateTime? lastValidTime;
    double splitStartElevation = 0;
    double currentElevation = 0;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.timestamp == null || p.lat == null || p.lng == null) continue;
      
      if (splitStartTime == null) {
        splitStartTime = p.timestamp;
        splitStartElevation = p.elevation ?? 0;
      }
      lastValidTime = p.timestamp;
      currentElevation = p.elevation ?? 0;

      if (i > 0) {
        final prev = points[i - 1];
        if (prev.lat != null && prev.lng != null && !p.isPaused) {
          final dist = distanceCalc.as(LengthUnit.Meter, LatLng(prev.lat!, prev.lng!), LatLng(p.lat!, p.lng!));
          accumulatedDistanceM += dist;
        }
      }

      if (accumulatedDistanceM >= currentKm * 1000) {
        final durationS = p.timestamp!.difference(splitStartTime!).inSeconds;
        splits.add(_SplitData(
          kmLabel: '$currentKm',
          paceSPerKm: durationS,
          elevationChange: (currentElevation - splitStartElevation).round(),
        ));
        
        currentKm++;
        splitStartTime = p.timestamp; // Reset for next split
        splitStartElevation = currentElevation;
      }
    }

    // Add partial last split if it's over 100m
    final partialDistance = accumulatedDistanceM - ((currentKm - 1) * 1000);
    if (partialDistance > 100 && splitStartTime != null && lastValidTime != null) {
      final durationS = lastValidTime.difference(splitStartTime).inSeconds;
      if (durationS > 0) {
        // Project pace to full km
        final projectedDurationS = (durationS / (partialDistance / 1000)).round();
        splits.add(_SplitData(
          kmLabel: (partialDistance / 1000).toStringAsFixed(1),
          paceSPerKm: projectedDurationS,
          elevationChange: (currentElevation - splitStartElevation).round(),
        ));
      }
    }

    return splits;
  }
}

class _SplitData {
  final String kmLabel;
  final int paceSPerKm;
  final int elevationChange;

  _SplitData({required this.kmLabel, required this.paceSPerKm, required this.elevationChange});
}

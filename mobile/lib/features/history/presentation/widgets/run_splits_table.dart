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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SPLITS', style: AppTextStyles.retroLabelLarge(color: colors.accent)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: splits.length,
            separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
            itemBuilder: (context, index) {
              final split = splits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${index + 1}',
                      style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                    ),
                    Text(
                      '${split.durationMins}:${split.durationSecs.toString().padLeft(2, '0')} /km',
                      style: AppTextStyles.bodyLarge(color: colors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
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

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.timestamp == null || p.lat == null || p.lng == null) continue;
      
      if (splitStartTime == null) {
        splitStartTime = p.timestamp;
      }
      lastValidTime = p.timestamp;

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
          km: currentKm,
          durationMins: durationS ~/ 60,
          durationSecs: durationS % 60,
        ));
        
        currentKm++;
        splitStartTime = p.timestamp; // Reset for next split
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
          km: currentKm,
          durationMins: projectedDurationS ~/ 60,
          durationSecs: projectedDurationS % 60,
        ));
      }
    }

    return splits;
  }
}

class _SplitData {
  final int km;
  final int durationMins;
  final int durationSecs;

  _SplitData({required this.km, required this.durationMins, required this.durationSecs});
}

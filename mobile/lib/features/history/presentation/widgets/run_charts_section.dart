import '../../domain/history_use_case_route_analytics.dart';
import '../../data/history_mapper_route_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_metric_chart.dart';
import 'package:trailhead_mobile/shared/state_management/global/distance_unit_cubit.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';

class RunChartsSection extends StatelessWidget {
  final RunIsar run;
  final List<RunPointIsar> points;

  const RunChartsSection({super.key, required this.run, required this.points});

  @override
  Widget build(BuildContext context) {
    final useMiles = context.watch<DistanceUnitCubit>().state;
    if (points.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColors>()!;

    final analytics = analyzeRoute(
      points.map(toRouteMetricPoint).toList(),
      storedPace: run.avgPaceSPerKm,
      storedCadence: run.avgCadenceSpm,
      storedElevation: run.elevationGainM,
      startTime: run.startTime,
      endTime: run.endTime,
      durationS: run.durationS,
      distanceM: run.distanceM,
    );
    List<ChartDataPoint> chart(List<RouteChartPoint> samples) =>
        samples.map((point) => ChartDataPoint(point.x, point.y)).toList();
    final paceData = chart(analytics.pace);
    final cadenceData = chart(analytics.cadence);
    final elevationData = chart(analytics.elevation);
    final (
      :avgPace,
      :avgCadence,
      :elevationGain,
      :maxElevation,
      :maxCadence,
      fastestPace: fastestPaceSPerKm,
      elapsedPace: elapsedPaceSPerKm,
      elapsedTime: elapsedTimeS,
      pace: _,
      cadence: _,
      elevation: _,
    ) = analytics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paceData.isNotEmpty) ...[
          RunMetricChart(
            title: 'Pace',
            type: MetricType.pace,
            data: paceData,
            color: Colors.blueAccent, // Use a static color or theme color
            average: avgPace > 0 ? avgPace : null,
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Avg Pace',
            avgPace > 0 ? _formatPace(avgPace, useMiles) : '--',
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Moving Time',
            run.durationS != null
                ? RunFormatUtils.formatDuration(run.durationS!)
                : '--',
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Avg Elapsed Pace',
            elapsedPaceSPerKm > 0
                ? _formatPace(elapsedPaceSPerKm, useMiles)
                : '--',
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Elapsed Time',
            elapsedTimeS > 0
                ? RunFormatUtils.formatDuration(elapsedTimeS)
                : '--',
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Fastest Split',
            fastestPaceSPerKm > 0
                ? _formatPace(fastestPaceSPerKm, useMiles)
                : '--',
          ),
          const SizedBox(height: 32),
        ],

        if (cadenceData.isNotEmpty) ...[
          RunMetricChart(
            title: 'Cadence',
            type: MetricType.cadence,
            data: cadenceData,
            color: Colors.pinkAccent,
            average: avgCadence > 0 ? avgCadence : null,
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Avg Cadence',
            avgCadence > 0 ? '${avgCadence.round()} spm' : '--',
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Max Cadence',
            maxCadence > 0 ? '${maxCadence.round()} spm' : '--',
          ),
          const SizedBox(height: 32),
        ],

        if (elevationData.isNotEmpty) ...[
          RunMetricChart(
            title: 'Elevation',
            type: MetricType.elevation,
            data: elevationData,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Elevation Gain',
            '${elevationGain.round()} m',
          ),
          const SizedBox(height: 24),
          _buildStatListRow(
            colors,
            'Max Elevation',
            maxElevation > -9999 ? '${maxElevation.round()} m' : '--',
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildStatListRow(AppColors colors, String label, String value) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 4,
      spacing: 12,
      children: [
        Text(label, style: AppTextStyles.bodyLarge(color: colors.textPrimary)),
        Text(
          value,
          style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
        ),
      ],
    );
  }

  String _formatPace(double seconds, bool useMiles) =>
      '${RunFormatUtils.formatPaceSeconds(seconds, useMiles: useMiles)} /${RunFormatUtils.getUnitString(useMiles)}';
}

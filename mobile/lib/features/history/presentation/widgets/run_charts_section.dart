import 'package:flutter/material.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/run_metric_chart.dart';
import 'package:trailhead_mobile/features/run_tracking/application/tracking_calcs.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'dart:math';

class RunChartsSection extends StatelessWidget {
  final RunIsar run;
  final List<RunPointIsar> points;

  const RunChartsSection({
    super.key,
    required this.run,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColors>()!;
    
    // Process points into cumulative distance and charts
    double currentDistance = 0.0;
    RunPointIsar? lastPoint;

    final List<ChartDataPoint> paceData = [];
    final List<ChartDataPoint> cadenceData = [];
    final List<ChartDataPoint> elevationData = [];
    
    double maxElevation = -9999;
    double maxCadence = 0;
    double maxSpeed = 0; // for fastest split / pace

    for (final point in points) {
      if (lastPoint != null && point.lat != null && point.lng != null && lastPoint.lat != null && lastPoint.lng != null) {
        currentDistance += TrackingCalcs.calculateDistance(
          lastPoint.lat!, lastPoint.lng!, point.lat!, point.lng!
        );
      }
      
      final currentDistKm = currentDistance / 1000.0;
      
      double? currentSpeed = point.speed;
      if (currentSpeed == null && lastPoint != null && point.lat != null && point.lng != null && lastPoint.lat != null && lastPoint.lng != null && point.timestamp != null && lastPoint.timestamp != null) {
        final dist = TrackingCalcs.calculateDistance(lastPoint.lat!, lastPoint.lng!, point.lat!, point.lng!);
        final timeDiff = point.timestamp!.difference(lastPoint.timestamp!).inSeconds.toDouble();
        if (timeDiff > 0) {
          currentSpeed = dist / timeDiff;
        }
      }

      // Pace (only if speed > 0)
      if (currentSpeed != null && currentSpeed > 0.1) {
        final paceSeconds = 1000.0 / currentSpeed;
        // Cap pace to reasonable running/walking bounds (e.g. max 20 min/km = 1200s)
        if (paceSeconds < 1200) {
          paceData.add(ChartDataPoint(currentDistKm, paceSeconds));
        }
        maxSpeed = max(maxSpeed, currentSpeed);
      }
      
      // Cadence
      if (point.cadence != null && point.cadence! > 0) {
        cadenceData.add(ChartDataPoint(currentDistKm, point.cadence!.toDouble()));
        maxCadence = max(maxCadence, point.cadence!.toDouble());
      }
      
      // Elevation
      if (point.elevation != null) {
        elevationData.add(ChartDataPoint(currentDistKm, point.elevation!));
        maxElevation = max(maxElevation, point.elevation!);
      }
      
      lastPoint = point;
    }

    final double avgPace = run.avgPaceSPerKm ?? 0;
    final double avgCadence = run.avgCadenceSpm ?? 0;
    // Use stored elevation gain; fall back to computing from raw points
    final double elevationGain = (run.elevationGainM != null && run.elevationGainM! > 0)
        ? run.elevationGainM!
        : _computeElevationGainFromPoints(points);
    final double fastestPaceSPerKm = maxSpeed > 0 ? (1000.0 / maxSpeed) : 0;
    
    final int elapsedTimeS = (run.endTime != null && run.startTime != null)
        ? run.endTime!.difference(run.startTime!).inSeconds
        : (run.durationS ?? 0);
        
    final double elapsedPaceSPerKm = (run.distanceM != null && run.distanceM! > 0) 
        ? elapsedTimeS / (run.distanceM! / 1000.0) 
        : 0;

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
          _buildStatListRow(colors, 'Avg Pace', avgPace > 0 ? _formatPace(avgPace) : '--'),
          const SizedBox(height: 24),
          _buildStatListRow(colors, 'Moving Time', run.durationS != null ? RunFormatUtils.formatDuration(run.durationS!) : '--'),
          const SizedBox(height: 24),
          _buildStatListRow(colors, 'Avg Elapsed Pace', elapsedPaceSPerKm > 0 ? _formatPace(elapsedPaceSPerKm) : '--'),
          const SizedBox(height: 24),
          _buildStatListRow(colors, 'Elapsed Time', elapsedTimeS > 0 ? RunFormatUtils.formatDuration(elapsedTimeS) : '--'),
          const SizedBox(height: 24),
          _buildStatListRow(colors, 'Fastest Split', fastestPaceSPerKm > 0 ? _formatPace(fastestPaceSPerKm) : '--'),
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
          _buildStatListRow(colors, 'Avg Cadence', avgCadence > 0 ? '${avgCadence.round()} spm' : '--'),
          const SizedBox(height: 24),
          _buildStatListRow(colors, 'Max Cadence', maxCadence > 0 ? '${maxCadence.round()} spm' : '--'),
          const SizedBox(height: 32),
        ],
        
        if (elevationData.isNotEmpty) ...[
          RunMetricChart(
            title: 'Elevation',
            type: MetricType.elevation,
            data: elevationData,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          _buildStatRow(colors, [
            _StatItem('Elevation Gain', '${elevationGain.round()} m'),
            _StatItem('Max Elevation', maxElevation > -9999 ? '${maxElevation.round()} m' : '--'),
          ]),
        ],
      ],
    );
  }

  Widget _buildStatRow(AppColors colors, List<_StatItem> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: stats.map((stat) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.label, style: AppTextStyles.label(color: colors.textSecondary)),
          const SizedBox(height: 4),
          Text(stat.value, style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
        ],
      )).toList(),
    );
  }

  Widget _buildStatListRow(AppColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyLarge(color: colors.textPrimary)),
        Text(value, style: AppTextStyles.bodyLargeBold(color: colors.textPrimary)),
      ],
    );
  }

  String _formatPace(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  /// Computes elevation gain from raw GPS points using a 3-point smoothing
  /// window — mirrors the algorithm used during live tracking.
  double _computeElevationGainFromPoints(List<RunPointIsar> pts) {
    final elevPoints = pts.where((p) => p.elevation != null && !p.isPaused).toList();
    if (elevPoints.length < 3) return 0.0;

    double gain = 0.0;
    final List<double> buffer = [];
    double? lastSmoothed;

    for (final point in elevPoints) {
      buffer.add(point.elevation!);
      if (buffer.length > 3) buffer.removeAt(0);
      if (buffer.length == 3) {
        final smoothed = buffer.reduce((a, b) => a + b) / 3.0;
        if (lastSmoothed != null) {
          final delta = smoothed - lastSmoothed;
          if (delta > 0) gain += delta;
        }
        lastSmoothed = smoothed;
      }
    }
    return gain;
  }
}

class _StatItem {
  final String label;
  final String value;
  _StatItem(this.label, this.value);
}

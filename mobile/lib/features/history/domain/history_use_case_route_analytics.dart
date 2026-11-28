import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../run_tracking/domain/run_tracking_use_case_calculations.dart';

typedef RouteMetricPoint = ({
  double? lat,
  double? lng,
  DateTime? timestamp,
  double? speed,
  double? elevation,
  int? cadence,
  bool isPaused,
});
typedef RouteChartPoint = ({double x, double y});
typedef RouteAnalytics = ({
  List<RouteChartPoint> pace,
  List<RouteChartPoint> cadence,
  List<RouteChartPoint> elevation,
  double maxCadence,
  double maxElevation,
  double avgPace,
  double avgCadence,
  double elevationGain,
  double fastestPace,
  double elapsedPace,
  int elapsedTime,
});

RouteAnalytics analyzeRoute(
  List<RouteMetricPoint> points, {
  double? storedPace,
  double? storedCadence,
  double? storedElevation,
  DateTime? startTime,
  DateTime? endTime,
  int? durationS,
  double? distanceM,
}) {
  // Process points into cumulative distance and charts
  double currentDistance = 0.0;
  RouteMetricPoint? lastPoint;

  final List<RouteChartPoint> paceData = [];
  final List<RouteChartPoint> cadenceData = [];
  final List<RouteChartPoint> elevationData = [];

  double maxElevation = -9999;
  double maxCadence = 0;
  double maxSpeed = 0; // for fastest split / pace

  for (final point in points) {
    if (lastPoint != null &&
        point.lat != null &&
        point.lng != null &&
        lastPoint.lat != null &&
        lastPoint.lng != null) {
      currentDistance += TrackingCalcs.calculateDistance(
        lastPoint.lat!,
        lastPoint.lng!,
        point.lat!,
        point.lng!,
      );
    }

    final currentDistKm = currentDistance / 1000.0;

    double? currentSpeed = point.speed;
    if (currentSpeed == null &&
        lastPoint != null &&
        point.lat != null &&
        point.lng != null &&
        lastPoint.lat != null &&
        lastPoint.lng != null &&
        point.timestamp != null &&
        lastPoint.timestamp != null) {
      final dist = TrackingCalcs.calculateDistance(
        lastPoint.lat!,
        lastPoint.lng!,
        point.lat!,
        point.lng!,
      );
      final timeDiff = point.timestamp!
          .difference(lastPoint.timestamp!)
          .inSeconds
          .toDouble();
      if (timeDiff > 0) {
        currentSpeed = dist / timeDiff;
      }
    }

    // Pace (only if speed > 0)
    if (currentSpeed != null && currentSpeed > 0.1) {
      final rawPaceSeconds = 1000.0 / currentSpeed;
      if (rawPaceSeconds < 1200) {
        // Simple smoothing using previous points
        double smoothedPace = rawPaceSeconds;
        if (paceData.length >= 2) {
          smoothedPace =
              (paceData[paceData.length - 2].y +
                  paceData[paceData.length - 1].y +
                  rawPaceSeconds) /
              3.0;
        } else if (paceData.isNotEmpty) {
          smoothedPace = (paceData.last.y + rawPaceSeconds) / 2.0;
        }
        paceData.add((x: currentDistKm, y: smoothedPace));
      }
      maxSpeed = max(maxSpeed, currentSpeed);
    }

    // Cadence
    if (point.cadence != null && point.cadence! > 0) {
      cadenceData.add((x: currentDistKm, y: point.cadence!.toDouble()));
      maxCadence = max(maxCadence, point.cadence!.toDouble());
    }

    // Elevation
    if (point.elevation != null) {
      elevationData.add((x: currentDistKm, y: point.elevation!));
      maxElevation = max(maxElevation, point.elevation!);
    }

    lastPoint = point;
  }

  final double avgPace = storedPace ?? 0;
  final double avgCadence = storedCadence ?? 0;
  // Use stored elevation gain; fall back to computing from raw points
  final double elevationGain = (storedElevation != null && storedElevation > 0)
      ? storedElevation
      : _computeElevationGainFromPoints(points);
  final double fastestPaceSPerKm = maxSpeed > 0 ? (1000.0 / maxSpeed) : 0;

  final int elapsedTimeS = (endTime != null && startTime != null)
      ? endTime.difference(startTime).inSeconds
      : (durationS ?? 0);

  final double elapsedPaceSPerKm = (distanceM != null && distanceM > 0)
      ? elapsedTimeS / (distanceM / 1000.0)
      : 0;
  return (
    pace: paceData,
    cadence: cadenceData,
    elevation: elevationData,
    maxCadence: maxCadence,
    maxElevation: maxElevation,
    avgPace: avgPace,
    avgCadence: avgCadence,
    elevationGain: elevationGain,
    fastestPace: fastestPaceSPerKm,
    elapsedPace: elapsedPaceSPerKm,
    elapsedTime: elapsedTimeS,
  );
}

/// Computes elevation gain from raw GPS points using a 3-point smoothing
/// window — mirrors the algorithm used during live tracking.
double _computeElevationGainFromPoints(List<RouteMetricPoint> pts) {
  final elevPoints = pts
      .where((p) => p.elevation != null && !p.isPaused)
      .toList();
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

List<ActivitySplit> calculateActivitySplits(List<RouteMetricPoint> points) {
  if (points.isEmpty) return [];

  final distanceCalc = const Distance();
  final splits = <ActivitySplit>[];

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
        final dist = distanceCalc.as(
          LengthUnit.Meter,
          LatLng(prev.lat!, prev.lng!),
          LatLng(p.lat!, p.lng!),
        );
        accumulatedDistanceM += dist;
      }
    }

    if (accumulatedDistanceM >= currentKm * 1000) {
      final durationS = p.timestamp!.difference(splitStartTime!).inSeconds;
      splits.add(
        ActivitySplit(
          kmLabel: '$currentKm',
          paceSPerKm: durationS,
          elevationChange: (currentElevation - splitStartElevation).round(),
        ),
      );

      currentKm++;
      splitStartTime = p.timestamp; // Reset for next split
      splitStartElevation = currentElevation;
    }
  }

  // Add partial last split if it's over 100m
  final partialDistance = accumulatedDistanceM - ((currentKm - 1) * 1000);
  if (partialDistance > 100 &&
      splitStartTime != null &&
      lastValidTime != null) {
    final durationS = lastValidTime.difference(splitStartTime).inSeconds;
    if (durationS > 0) {
      // Project pace to full km
      final projectedDurationS = (durationS / (partialDistance / 1000)).round();
      splits.add(
        ActivitySplit(
          kmLabel: (partialDistance / 1000).toStringAsFixed(1),
          paceSPerKm: projectedDurationS,
          elevationChange: (currentElevation - splitStartElevation).round(),
        ),
      );
    }
  }

  return splits;
}

class ActivitySplit {
  final String kmLabel;
  final int paceSPerKm;
  final int elevationChange;

  ActivitySplit({
    required this.kmLabel,
    required this.paceSPerKm,
    required this.elevationChange,
  });
}

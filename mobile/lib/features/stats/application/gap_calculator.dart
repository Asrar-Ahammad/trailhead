import 'dart:math';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';

abstract final class GapCalculator {
  static const double _earthRadius = 6371e3;
  static const double _flatCost = 3.6;

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadius * c;
  }

  static double _gradeCostFactor(double gradeDecimal) {
    final i = gradeDecimal;
    final i2 = i * i;
    final i3 = i2 * i;
    final i4 = i3 * i;
    final i5 = i4 * i;

    final cost = 155.4 * i5 - 30.4 * i4 - 43.3 * i3 + 46.3 * i2 + 19.5 * i + _flatCost;
    return cost / _flatCost;
  }

  static double? computeGap(List<RunPointIsar> rawPoints) {
    // Filter to points with valid data and not paused
    final points = rawPoints.where((p) => 
      p.elevation != null && 
      p.lat != null && 
      p.lng != null && 
      p.timestamp != null && 
      !p.isPaused
    ).toList();
    
    if (points.length < 2) return null;

    final altitudeBuffer = <double>[];
    double? lastSmoothedAlt;
    DateTime lastPointTime = points.first.timestamp!;
    double lastPointLat = points.first.lat!;
    double lastPointLng = points.first.lng!;

    altitudeBuffer.add(points.first.elevation!);

    double totalWeightedGapSPerKm = 0;
    double totalDistanceM = 0;
    bool hasValidElevation = false;

    const double maxGrade = 0.40;
    const double minGrade = -0.40;
    double lastValidGrade = 0;

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      altitudeBuffer.add(p.elevation!);
      if (altitudeBuffer.length > 3) {
        altitudeBuffer.removeAt(0);
      }

      double? currentSmoothedAlt;
      if (altitudeBuffer.length == 3) {
        currentSmoothedAlt = (altitudeBuffer[0] + altitudeBuffer[1] + altitudeBuffer[2]) / 3.0;
      }

      final dist = _haversine(lastPointLat, lastPointLng, p.lat!, p.lng!);
      final durationS = p.timestamp!.difference(lastPointTime).inMilliseconds / 1000.0;

      if (dist > 0 && durationS > 0) {
        double gradeDecimal = 0;
        if (lastSmoothedAlt != null && currentSmoothedAlt != null) {
          final deltaAlt = currentSmoothedAlt - lastSmoothedAlt;
          gradeDecimal = deltaAlt / dist;
        }

        double grade = gradeDecimal;
        if (grade > maxGrade || grade < minGrade) {
          grade = lastValidGrade;
        } else {
          lastValidGrade = grade;
          if (grade != 0) hasValidElevation = true;
        }

        final costFactor = _gradeCostFactor(grade);
        final segmentRawPaceSPerKm = (durationS / dist) * 1000;
        final segmentGapPaceSPerKm = segmentRawPaceSPerKm / costFactor;

        totalWeightedGapSPerKm += segmentGapPaceSPerKm * dist;
        totalDistanceM += dist;
      }

      lastPointLat = p.lat!;
      lastPointLng = p.lng!;
      lastPointTime = p.timestamp!;

      if (currentSmoothedAlt != null) {
        lastSmoothedAlt = currentSmoothedAlt;
      }
    }

    if (!hasValidElevation || totalDistanceM == 0) return null;

    return totalWeightedGapSPerKm / totalDistanceM;
  }
}

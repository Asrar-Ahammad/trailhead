import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/features/run_tracking/application/tracking_calcs.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';

/// A single evaluated sample along the flyover playback timeline.
class FlyoverSample {
  final LatLng point;
  final double bearing; // In degrees, 0..360 (0 = North, 90 = East)
  final double distanceM; // Cumulative meters from start
  final int elapsedS; // Elapsed seconds from start
  final double paceSPerKm; // Instantaneous smoothed pace in s/km
  final double elevationM; // Altitude in meters
  final double speedMPerS; // Current speed
  final int? cadence; // SPM if available
  final double progress; // 0.0 to 1.0
  final double zoom; // Dynamic zoom level calculated from path scale and progression

  const FlyoverSample({
    required this.point,
    required this.bearing,
    required this.distanceM,
    required this.elapsedS,
    required this.paceSPerKm,
    required this.elevationM,
    required this.speedMPerS,
    this.cadence,
    required this.progress,
    this.zoom = 16.5,
  });

  FlyoverSample copyWith({
    LatLng? point,
    double? bearing,
    double? distanceM,
    int? elapsedS,
    double? paceSPerKm,
    double? elevationM,
    double? speedMPerS,
    int? cadence,
    double? progress,
    double? zoom,
  }) {
    return FlyoverSample(
      point: point ?? this.point,
      bearing: bearing ?? this.bearing,
      distanceM: distanceM ?? this.distanceM,
      elapsedS: elapsedS ?? this.elapsedS,
      paceSPerKm: paceSPerKm ?? this.paceSPerKm,
      elevationM: elevationM ?? this.elevationM,
      speedMPerS: speedMPerS ?? this.speedMPerS,
      cadence: cadence ?? this.cadence,
      progress: progress ?? this.progress,
      zoom: zoom ?? this.zoom,
    );
  }
}

/// Represents a distance milestone (e.g. 1 km, 2 km or 1 mi, 2 mi).
class FlyoverMilestone {
  final int number;
  final String label;
  final LatLng point;
  final double progress;
  final double distanceM;

  const FlyoverMilestone({
    required this.number,
    required this.label,
    required this.point,
    required this.progress,
    required this.distanceM,
  });
}

/// Pre-processed timeline and geometry model for smooth 60fps flyover playback.
class FlyoverTimeline {
  final List<FlyoverSample> rawSamples;
  final List<LatLng> fullRoutePoints;
  final List<FlyoverMilestone> milestones;
  final double totalDistanceM;
  final int totalDurationS;
  final double minElevationM;
  final double maxElevationM;
  final double baseZoom;

  FlyoverTimeline({
    required this.rawSamples,
    required this.fullRoutePoints,
    required this.milestones,
    required this.totalDistanceM,
    required this.totalDurationS,
    required this.minElevationM,
    required this.maxElevationM,
    this.baseZoom = 16.5,
  });

  bool get isEmpty => rawSamples.isEmpty;
  bool get isNotEmpty => rawSamples.isNotEmpty;

  /// Calculates the optimal base camera zoom based on the geographic bounding size of the route.
  static double calculateOptimalBaseZoom(List<LatLng> route, double totalDistanceM) {
    if (route.isEmpty) return 16.5;

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (final p in route) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latSpanM = TrackingCalcs.calculateDistance(minLat, minLng, maxLat, minLng);
    final lngSpanM = TrackingCalcs.calculateDistance(minLat, minLng, minLat, maxLng);
    final maxSpanM = max(latSpanM, lngSpanM);

    // Dynamic zoom based on geographic footprint size:
    // < 400m (small track or neighborhood loop): 17.5
    // 400m - 1.2km: 16.8
    // 1.2km - 3.5km: 16.2
    // 3.5km - 8km: 15.6
    // 8km - 18km: 15.0
    // > 18km (Marathons / ultra runs): 14.4
    if (maxSpanM < 400) {
      return 17.5;
    } else if (maxSpanM < 1200) {
      return 16.8;
    } else if (maxSpanM < 3500) {
      return 16.2;
    } else if (maxSpanM < 8000) {
      return 15.6;
    } else if (maxSpanM < 18000) {
      return 15.0;
    } else {
      return 14.4;
    }
  }

  /// Builds a [FlyoverTimeline] from a chronologically sorted list of [RunPointIsar].
  factory FlyoverTimeline.fromRunPoints(
    List<RunPointIsar> rawPoints, {
    bool useMiles = false,
    double? fallbackDurationS,
    double? fallbackDistanceM,
    double? fallbackAvgPaceSPerKm,
  }) {
    // Filter out invalid GPS points
    final validPoints = rawPoints
        .where((p) => p.lat != null && p.lng != null && (p.lat != 0.0 || p.lng != 0.0))
        .toList();

    if (validPoints.length < 2) {
      // Return empty or single point timeline
      final samples = <FlyoverSample>[];
      final route = <LatLng>[];
      if (validPoints.length == 1) {
        final p = validPoints.first;
        final latLng = LatLng(p.lat!, p.lng!);
        route.add(latLng);
        samples.add(FlyoverSample(
          point: latLng,
          bearing: 0.0,
          distanceM: 0.0,
          elapsedS: 0,
          paceSPerKm: fallbackAvgPaceSPerKm ?? 300.0,
          elevationM: p.elevation ?? 0.0,
          speedMPerS: p.speed ?? 0.0,
          cadence: p.cadence,
          progress: 1.0,
          zoom: 16.5,
        ));
      }
      return FlyoverTimeline(
        rawSamples: samples,
        fullRoutePoints: route,
        milestones: const [],
        totalDistanceM: fallbackDistanceM ?? 0.0,
        totalDurationS: fallbackDurationS?.round() ?? 0,
        minElevationM: 0.0,
        maxElevationM: 0.0,
        baseZoom: 16.5,
      );
    }

    final fullRoute = <LatLng>[];
    final samples = <FlyoverSample>[];
    final milestones = <FlyoverMilestone>[];

    double cumDist = 0.0;
    final startTime = validPoints.first.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    double minEle = validPoints.first.elevation ?? 0.0;
    double maxEle = minEle;

    // Track milestone distance intervals (1000m for km, 1609.34m for miles)
    final milestoneIntervalM = useMiles ? 1609.344 : 1000.0;
    int nextMilestoneNumber = 1;

    for (int i = 0; i < validPoints.length; i++) {
      final cur = validPoints[i];
      final curLatLng = LatLng(cur.lat!, cur.lng!);
      fullRoute.add(curLatLng);

      if (i > 0) {
        final prev = validPoints[i - 1];
        final d = TrackingCalcs.calculateDistance(prev.lat!, prev.lng!, cur.lat!, cur.lng!);
        cumDist += d;
      }

      final ele = cur.elevation ?? 0.0;
      if (ele < minEle) minEle = ele;
      if (ele > maxEle) maxEle = ele;

      // Check milestones
      while (cumDist >= nextMilestoneNumber * milestoneIntervalM) {
        final unitLabel = useMiles ? 'mi' : 'km';
        milestones.add(FlyoverMilestone(
          number: nextMilestoneNumber,
          label: '$nextMilestoneNumber $unitLabel',
          point: curLatLng,
          progress: 0.0, // Will recalculate after total distance is known
          distanceM: nextMilestoneNumber * milestoneIntervalM,
        ));
        nextMilestoneNumber++;
      }
    }

    final totalDist = cumDist > 0 ? cumDist : (fallbackDistanceM ?? 0.0);
    final totalDuration = validPoints.last.timestamp != null && validPoints.first.timestamp != null
        ? validPoints.last.timestamp!.difference(startTime).inSeconds
        : (fallbackDurationS?.round() ?? 0);
    final baseZoom = calculateOptimalBaseZoom(fullRoute, totalDist);

    // Compute bearings and pace with a smoothed rolling window
    double runningDist = 0.0;
    for (int i = 0; i < validPoints.length; i++) {
      final cur = validPoints[i];
      final curLatLng = fullRoute[i];

      if (i > 0) {
        final prev = validPoints[i - 1];
        runningDist += TrackingCalcs.calculateDistance(prev.lat!, prev.lng!, cur.lat!, cur.lng!);
      }

      // Forward lookahead bearing: look ahead along the path until at least 25-35 meters
      // to eliminate GPS jitter and micro-heading vibrations
      double bearing = 0.0;
      int targetIdx = i + 1;
      double lookaheadM = 0.0;
      while (targetIdx < validPoints.length) {
        final pA = validPoints[targetIdx - 1];
        final pB = validPoints[targetIdx];
        lookaheadM += TrackingCalcs.calculateDistance(pA.lat!, pA.lng!, pB.lat!, pB.lng!);
        if (lookaheadM >= 25.0 || targetIdx == validPoints.length - 1) {
          break;
        }
        targetIdx++;
      }
      if (targetIdx < validPoints.length) {
        final targetP = validPoints[targetIdx];
        bearing = _calculateBearing(cur.lat!, cur.lng!, targetP.lat!, targetP.lng!);
      } else if (samples.isNotEmpty) {
        bearing = samples.last.bearing;
      }

      // Elapsed time
      int elapsedS = 0;
      if (cur.timestamp != null) {
        elapsedS = cur.timestamp!.difference(startTime).inSeconds;
      } else if (totalDist > 0 && totalDuration > 0) {
        elapsedS = ((runningDist / totalDist) * totalDuration).round();
      }

      // Smoothed Pace: use point speed if realistic, else local window delta
      double paceSPerKm = fallbackAvgPaceSPerKm ?? 300.0;
      if (cur.speed != null && cur.speed! > 0.5 && cur.speed! < 15.0) {
        paceSPerKm = 1000.0 / cur.speed!;
      } else if (i > 0 && i < validPoints.length) {
        final prev = validPoints[i - 1];
        final dt = cur.timestamp != null && prev.timestamp != null
            ? cur.timestamp!.difference(prev.timestamp!).inSeconds.toDouble()
            : 0.0;
        final dd = TrackingCalcs.calculateDistance(prev.lat!, prev.lng!, cur.lat!, cur.lng!);
        if (dt > 0.5 && dd > 2.0) {
          final speed = dd / dt;
          if (speed > 0.5 && speed < 15.0) {
            paceSPerKm = 1000.0 / speed;
          }
        }
      }

      final progress = totalDist > 0 ? (runningDist / totalDist).clamp(0.0, 1.0) : (i / (validPoints.length - 1));

      // Dynamic zoom adjustments based on path progression & speed
      double zoomDelta = 0.0;
      if (progress < 0.08) {
        // Intro: smooth zoom in from wide overview (-0.75) to baseZoom
        final factor = (progress / 0.08).clamp(0.0, 1.0);
        zoomDelta = -0.75 * (1.0 - factor);
      } else if (progress > 0.90) {
        // Outro: smooth zoom out (-0.75) to reveal full completed route at finish
        final factor = ((progress - 0.90) / 0.10).clamp(0.0, 1.0);
        zoomDelta = -0.75 * factor;
      } else if (paceSPerKm > 0) {
        if (paceSPerKm < 240) {
          zoomDelta -= 0.2; // Fast segments pull back slightly for wider visibility
        } else if (paceSPerKm > 360) {
          zoomDelta += 0.25; // Slower/winding segments zoom in closer
        }
      }
      final pointZoom = (baseZoom + zoomDelta).clamp(13.5, 18.0);

      samples.add(FlyoverSample(
        point: curLatLng,
        bearing: bearing,
        distanceM: runningDist,
        elapsedS: elapsedS,
        paceSPerKm: paceSPerKm.clamp(120.0, 1200.0), // 2:00/km to 20:00/km reasonable clamp
        elevationM: cur.elevation ?? 0.0,
        speedMPerS: cur.speed ?? (paceSPerKm > 0 ? 1000.0 / paceSPerKm : 0.0),
        cadence: cur.cadence,
        progress: progress,
        zoom: pointZoom,
      ));
    }

    // Filter across all sample bearings and zooms (window radius = 4)
    // for drone/gimbal-like rotational and focal stability
    final smoothedSamples = <FlyoverSample>[];
    for (int i = 0; i < samples.length; i++) {
      double sumSin = 0.0;
      double sumCos = 0.0;
      double sumZoom = 0.0;
      int count = 0;
      for (int w = -4; w <= 4; w++) {
        final idx = i + w;
        if (idx >= 0 && idx < samples.length) {
          final rad = samples[idx].bearing * pi / 180.0;
          sumSin += sin(rad);
          sumCos += cos(rad);
          sumZoom += samples[idx].zoom;
          count++;
        }
      }
      double smoothedBearing = samples[i].bearing;
      if (count > 0 && (sumSin.abs() > 0.00001 || sumCos.abs() > 0.00001)) {
        final avgRad = atan2(sumSin / count, sumCos / count);
        smoothedBearing = (avgRad * 180.0 / pi + 360.0) % 360.0;
      }
      final smoothedZoom = count > 0 ? (sumZoom / count) : samples[i].zoom;
      smoothedSamples.add(samples[i].copyWith(
        bearing: smoothedBearing,
        zoom: smoothedZoom,
      ));
    }

    // Recalculate milestone progress accurately
    final updatedMilestones = milestones.map((m) {
      final prog = totalDist > 0 ? (m.distanceM / totalDist).clamp(0.0, 1.0) : 0.0;
      return FlyoverMilestone(
        number: m.number,
        label: m.label,
        point: m.point,
        progress: prog,
        distanceM: m.distanceM,
      );
    }).toList();

    return FlyoverTimeline(
      rawSamples: smoothedSamples,
      fullRoutePoints: fullRoute,
      milestones: updatedMilestones,
      totalDistanceM: totalDist,
      totalDurationS: totalDuration > 0 ? totalDuration : (fallbackDurationS?.round() ?? 0),
      minElevationM: minEle,
      maxElevationM: maxEle,
      baseZoom: baseZoom,
    );
  }

  /// Evaluates an interpolated [FlyoverSample] at a continuous [progress] between 0.0 and 1.0.
  FlyoverSample sampleAt(double progress) {
    if (rawSamples.isEmpty) {
      return const FlyoverSample(
        point: LatLng(0, 0),
        bearing: 0,
        distanceM: 0,
        elapsedS: 0,
        paceSPerKm: 300,
        elevationM: 0,
        speedMPerS: 0,
        progress: 0,
        zoom: 16.5,
      );
    }
    if (progress <= 0.0 || rawSamples.length == 1) {
      return rawSamples.first;
    }
    if (progress >= 1.0) {
      return rawSamples.last;
    }

    // Binary search for the segment containing progress
    int low = 0;
    int high = rawSamples.length - 1;

    while (low < high - 1) {
      final mid = (low + high) >> 1;
      if (rawSamples[mid].progress <= progress) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final s0 = rawSamples[low];
    final s1 = rawSamples[high];

    final denom = s1.progress - s0.progress;
    final double f = denom > 0.000001 ? ((progress - s0.progress) / denom).clamp(0.0, 1.0) : 0.0;

    // Linear coordinates interpolation
    final lat = s0.point.latitude + (s1.point.latitude - s0.point.latitude) * f;
    final lng = s0.point.longitude + (s1.point.longitude - s0.point.longitude) * f;
    final point = LatLng(lat, lng);

    // Shortest angular arc interpolation for smooth camera rotation
    final bearing = _lerpAngle(s0.bearing, s1.bearing, f);

    // Interpolate metrics & dynamic zoom
    final distanceM = s0.distanceM + (s1.distanceM - s0.distanceM) * f;
    final elapsedS = (s0.elapsedS + (s1.elapsedS - s0.elapsedS) * f).round();
    final paceSPerKm = s0.paceSPerKm + (s1.paceSPerKm - s0.paceSPerKm) * f;
    final elevationM = s0.elevationM + (s1.elevationM - s0.elevationM) * f;
    final speedMPerS = s0.speedMPerS + (s1.speedMPerS - s0.speedMPerS) * f;
    final zoom = s0.zoom + (s1.zoom - s0.zoom) * f;

    return FlyoverSample(
      point: point,
      bearing: bearing,
      distanceM: distanceM,
      elapsedS: elapsedS,
      paceSPerKm: paceSPerKm,
      elevationM: elevationM,
      speedMPerS: speedMPerS,
      cadence: f < 0.5 ? s0.cadence : s1.cadence,
      progress: progress,
      zoom: zoom,
    );
  }

  /// Returns the subset of route points up to [progress], appending the interpolated position.
  List<LatLng> getTraveledPoints(double progress) {
    if (fullRoutePoints.isEmpty) return const [];
    if (progress <= 0.0) return [fullRoutePoints.first];
    if (progress >= 1.0) return fullRoutePoints;

    int low = 0;
    int high = rawSamples.length - 1;
    while (low < high - 1) {
      final mid = (low + high) >> 1;
      if (rawSamples[mid].progress <= progress) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final result = fullRoutePoints.sublist(0, low + 1);
    final currentSample = sampleAt(progress);
    result.add(currentSample.point);
    return result;
  }

  /// Returns the forward (untraveled) subset of route points from [progress] to finish.
  List<LatLng> getRemainingPoints(double progress) {
    if (fullRoutePoints.isEmpty) return const [];
    if (progress >= 1.0) return const [];
    if (progress <= 0.0) return fullRoutePoints;

    int low = 0;
    int high = rawSamples.length - 1;
    while (low < high - 1) {
      final mid = (low + high) >> 1;
      if (rawSamples[mid].progress <= progress) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final currentSample = sampleAt(progress);
    final result = <LatLng>[currentSample.point];
    if (high < fullRoutePoints.length) {
      result.addAll(fullRoutePoints.sublist(high));
    }
    return result;
  }

  static double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * pi / 180.0;
    final lat1Rad = lat1 * pi / 180.0;
    final lat2Rad = lat2 * pi / 180.0;
    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    final rad = atan2(y, x);
    return (rad * 180.0 / pi + 360.0) % 360.0;
  }

  static double _lerpAngle(double a, double b, double t) {
    double diff = (b - a) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return (a + diff * t) % 360.0;
  }
}

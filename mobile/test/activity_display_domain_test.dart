import 'package:trailhead_mobile/features/history/domain/history_use_case_route_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/history/domain/history_use_case_elevation_gain.dart';
import 'package:trailhead_mobile/features/run_tracking/domain/run_tracking_use_case_format_activity.dart';

void main() {
  test('route charts and splits derive elapsed pace from sampled activity', () {
    final start = DateTime(2026, 11, 28);
    final route = <RouteMetricPoint>[
      (
        lat: 0,
        lng: 0,
        timestamp: start,
        speed: 2.5,
        elevation: 10,
        cadence: 160,
        isPaused: false,
      ),
      (
        lat: 0,
        lng: 0.01,
        timestamp: start.add(const Duration(minutes: 5)),
        speed: null,
        elevation: 12,
        cadence: 170,
        isPaused: false,
      ),
    ];
    final analytics = analyzeRoute(
      route,
      startTime: start,
      endTime: route.last.timestamp,
      distanceM: 1200,
    );
    expect(analytics.elapsedPace, 250);
    expect(analytics.pace, hasLength(2));
    expect(analytics.maxCadence, 170);
    expect(calculateActivitySplits(route).first.paceSPerKm, 300);
  });
  test('rounded pace carries seconds into the minute and converts miles', () {
    expect(RunFormatUtils.formatPaceSeconds(299.7, useMiles: false), '05:00');
    expect(RunFormatUtils.formatPaceSeconds(240, useMiles: true), '06:26');
    expect(
      RunFormatUtils.formatPaceSeconds(double.nan, useMiles: false),
      '-:--',
    );
  });

  test('elevation gain uses smoothed positive climbs', () {
    expect(calculateElevationGain([10, 11, 14, 12]), 2.5);
    expect(calculateElevationGain([12, 11, 10]), isNull);
  });
}

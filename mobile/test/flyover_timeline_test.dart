import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/history/domain/flyover_timeline_model.dart';
import 'package:trailhead_mobile/features/history/application/flyover_playback_controller.dart';
import 'package:trailhead_mobile/features/history/presentation/widgets/flyover_scrubber_controls.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';

void main() {
  group('FlyoverTimeline Tests', () {
    test('Constructs timeline correctly from RunPointIsar list', () {
      final now = DateTime(2026, 9, 4, 10, 0, 0);

      // Create a test 3-point route: ~1.1 km
      final p1 = RunPointIsar()
        ..lat = 37.7749
        ..lng = -122.4194
        ..elevation = 10.0
        ..timestamp = now
        ..speed = 3.0
        ..sequence = 0;

      final p2 = RunPointIsar()
        ..lat = 37.7794
        ..lng = -122.4194
        ..elevation = 15.0
        ..timestamp = now.add(const Duration(seconds: 150))
        ..speed = 3.3
        ..sequence = 1;

      final p3 = RunPointIsar()
        ..lat = 37.7840
        ..lng = -122.4194
        ..elevation = 22.0
        ..timestamp = now.add(const Duration(seconds: 300))
        ..speed = 3.2
        ..sequence = 2;

      final timeline = FlyoverTimeline.fromRunPoints([p1, p2, p3]);

      expect(timeline.isNotEmpty, isTrue);
      expect(timeline.fullRoutePoints.length, equals(3));
      expect(timeline.rawSamples.length, equals(3));
      expect(timeline.totalDistanceM, greaterThan(1000.0));
      expect(timeline.totalDurationS, equals(300));
      expect(timeline.minElevationM, equals(10.0));
      expect(timeline.maxElevationM, equals(22.0));
      // At least one 1km milestone should be detected
      expect(timeline.milestones.isNotEmpty, isTrue);
      expect(timeline.milestones.first.label, equals('1 km'));
    });

    test('sampleAt smoothly interpolates intermediate point and metrics', () {
      final now = DateTime(2026, 9, 4, 10, 0, 0);

      final p1 = RunPointIsar()
        ..lat = 10.0
        ..lng = 10.0
        ..elevation = 100.0
        ..timestamp = now
        ..speed = 4.0
        ..sequence = 0;

      final p2 = RunPointIsar()
        ..lat = 10.0
        ..lng = 10.01
        ..elevation = 150.0
        ..timestamp = now.add(const Duration(seconds: 100))
        ..speed = 4.0
        ..sequence = 1;

      final timeline = FlyoverTimeline.fromRunPoints([p1, p2]);

      // Start sample
      final startSample = timeline.sampleAt(0.0);
      expect(startSample.point.latitude, equals(10.0));
      expect(startSample.point.longitude, equals(10.0));
      expect(startSample.elevationM, equals(100.0));
      expect(startSample.elapsedS, equals(0));

      // Mid sample
      final midSample = timeline.sampleAt(0.5);
      expect(midSample.point.latitude, closeTo(10.0, 0.0001));
      expect(midSample.point.longitude, closeTo(10.005, 0.0001));
      expect(midSample.elevationM, closeTo(125.0, 0.1));
      expect(midSample.elapsedS, equals(50));

      // End sample
      final endSample = timeline.sampleAt(1.0);
      expect(endSample.point.latitude, equals(10.0));
      expect(endSample.point.longitude, equals(10.01));
      expect(endSample.elevationM, equals(150.0));
      expect(endSample.elapsedS, equals(100));
    });

    test('getTraveledPoints and getRemainingPoints partition route correctly', () {
      final now = DateTime.now();
      final points = List.generate(
        5,
        (i) => RunPointIsar()
          ..lat = 10.0 + (i * 0.01)
          ..lng = 20.0 + (i * 0.01)
          ..timestamp = now.add(Duration(seconds: i * 60))
          ..sequence = i,
      );

      final timeline = FlyoverTimeline.fromRunPoints(points);

      final traveledAtHalf = timeline.getTraveledPoints(0.5);
      expect(traveledAtHalf.length, greaterThanOrEqualTo(3));

      final remainingAtHalf = timeline.getRemainingPoints(0.5);
      expect(remainingAtHalf.length, greaterThanOrEqualTo(2));
    });

    test('FlyoverPlaybackNotifier seek and pause updates state predictably', () {
      final now = DateTime.now();
      final points = List.generate(
        4,
        (i) => RunPointIsar()
          ..lat = 37.77 + (i * 0.01)
          ..lng = -122.41 + (i * 0.01)
          ..elevation = 50.0 + (i * 10)
          ..timestamp = now.add(Duration(seconds: i * 30))
          ..sequence = i,
      );
      final timeline = FlyoverTimeline.fromRunPoints(points);
      final notifier = FlyoverPlaybackNotifier(timeline: timeline);

      // Default state
      expect(notifier.state.progress, equals(0.0));
      expect(notifier.state.isPlaying, isFalse);

      // Seek
      notifier.seek(0.5);
      expect(notifier.state.progress, equals(0.5));
      expect(notifier.state.currentSample.elevationM, closeTo(65.0, 1.0));

      // Speed cycle
      expect(notifier.state.speedMultiplier, equals(1.0));
      notifier.cycleSpeed();
      expect(notifier.state.speedMultiplier, equals(2.0));

      // Telemetry toggle
      expect(notifier.state.isTelemetryVisible, isTrue);
      notifier.toggleTelemetry();
      expect(notifier.state.isTelemetryVisible, isFalse);

      notifier.dispose();
    });

    test('Dynamic zoom scales with path bounding size and interpolates smoothly', () {
      final now = DateTime.now();

      // Compact neighborhood path (3 points within ~300 meters)
      final smallPoints = [
        RunPointIsar()..lat = 37.7700..lng = -122.4100..timestamp = now..sequence = 0,
        RunPointIsar()..lat = 37.7710..lng = -122.4105..timestamp = now.add(const Duration(seconds: 60))..sequence = 1,
        RunPointIsar()..lat = 37.7720..lng = -122.4110..timestamp = now.add(const Duration(seconds: 120))..sequence = 2,
      ];
      final smallTimeline = FlyoverTimeline.fromRunPoints(smallPoints);
      expect(smallTimeline.baseZoom, greaterThanOrEqualTo(17.0));

      // Large multi-kilometer path (spanning across city ~10km)
      final largePoints = [
        RunPointIsar()..lat = 37.7000..lng = -122.4100..timestamp = now..sequence = 0,
        RunPointIsar()..lat = 37.7500..lng = -122.4100..timestamp = now.add(const Duration(minutes: 30))..sequence = 1,
        RunPointIsar()..lat = 37.8000..lng = -122.4100..timestamp = now.add(const Duration(minutes: 60))..sequence = 2,
      ];
      final largeTimeline = FlyoverTimeline.fromRunPoints(largePoints);
      expect(largeTimeline.baseZoom, lessThan(smallTimeline.baseZoom));

      // Check sample zoom continuity
      final midSample = smallTimeline.sampleAt(0.5);
      expect(midSample.zoom, greaterThan(13.0));
      expect(midSample.zoom, lessThan(19.0));
    });

    testWidgets('FlyoverScrubberControls renders CustomPaint with full container width', (tester) async {
      final now = DateTime.now();
      final points = [
        RunPointIsar()..lat = 37.7700..lng = -122.4100..elevation = 812.0..timestamp = now..sequence = 0,
        RunPointIsar()..lat = 37.7710..lng = -122.4105..elevation = 815.0..timestamp = now.add(const Duration(seconds: 60))..sequence = 1,
        RunPointIsar()..lat = 37.7720..lng = -122.4110..elevation = 820.0..timestamp = now.add(const Duration(seconds: 120))..sequence = 2,
      ];
      final timeline = FlyoverTimeline.fromRunPoints(points);
      final notifier = FlyoverPlaybackNotifier(timeline: timeline);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [AppColors.dark],
          ),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: FlyoverScrubberControls(
                timeline: timeline,
                playbackState: notifier.state,
                controller: notifier,
              ),
            ),
          ),
        ),
      );

      // Verify widget exists
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      // Find the elevation profile CustomPaint (the one inside the timeline container)
      final renderBoxes = tester.renderObjectList<RenderBox>(customPaintFinder);
      final timelinePainterBox = renderBoxes.firstWhere((b) => b.size.height >= 48 && b.size.height <= 54);

      // Verify the width is expanded to full usable width (not 0 or 24px)
      expect(timelinePainterBox.size.width, greaterThan(300.0));
      expect(timelinePainterBox.size.height, greaterThanOrEqualTo(50.0));

      // Verify tap-seeking updates playback progress
      await tester.tapAt(timelinePainterBox.localToGlobal(Offset(timelinePainterBox.size.width * 0.75, 25.0)));
      await tester.pumpAndSettle();
      expect(notifier.state.progress, closeTo(0.75, 0.05));

      notifier.dispose();
    });
  });
}


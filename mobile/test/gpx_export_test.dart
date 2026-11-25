import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/history/application/gpx_export_util.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';

void main() {
  group('GpxExportUtil Tests', () {
    test('generateGpxXml escapes XML reserved characters in run titles', () {
      final run = RunIsar()..title = 'Hill & track <easy>';
      expect(
        GpxExportUtil.generateGpxXml(run, []),
        contains('<name>Hill &amp; track &lt;easy&gt;</name>'),
      );
    });

    test('generateGpxXml generates valid GPX structure with points', () {
      final now = DateTime.utc(2026, 9, 4, 8, 30, 0);
      final run = RunIsar()
        ..title = 'Morning Jog'
        ..startTime = now
        ..distanceM = 5000.0
        ..durationS = 1500
        ..activityType = 'run';

      final p1 = RunPointIsar()
        ..lat = 37.7749
        ..lng = -122.4194
        ..elevation = 15.0
        ..timestamp = now;

      final p2 = RunPointIsar()
        ..lat = 37.7755
        ..lng = -122.4180
        ..elevation = 16.5
        ..timestamp = now.add(const Duration(seconds: 30));

      final xml = GpxExportUtil.generateGpxXml(run, [p1, p2]);

      expect(xml.contains('<?xml version="1.0" encoding="UTF-8"?>'), isTrue);
      expect(xml.contains('<gpx version="1.1"'), isTrue);
      expect(xml.contains('<name>Morning Jog</name>'), isTrue);
      expect(xml.contains('<trkpt lat="37.7749" lon="-122.4194">'), isTrue);
      expect(xml.contains('<ele>15.0</ele>'), isTrue);
      expect(xml.contains('<trkpt lat="37.7755" lon="-122.418">'), isTrue);
      expect(xml.contains('</trkseg>'), isTrue);
      expect(xml.contains('</gpx>'), isTrue);
    });

    test('generateGpxXml filters out points with null coordinates', () {
      final now = DateTime.utc(2026, 9, 4, 8, 30, 0);
      final run = RunIsar()
        ..title = 'Valid Track'
        ..startTime = now;

      final validPoint = RunPointIsar()
        ..lat = 37.7749
        ..lng = -122.4194
        ..timestamp = now;

      final invalidPoint = RunPointIsar()
        ..lat = null
        ..lng = -122.4194
        ..timestamp = now;

      final xml = GpxExportUtil.generateGpxXml(run, [validPoint, invalidPoint]);

      expect(xml.contains('lat="37.7749"'), isTrue);
      expect(xml.split('<trkpt').length - 1, equals(1));
    });
  });
}

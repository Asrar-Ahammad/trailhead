import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../run_tracking/application/run_format_utils.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';

class GpxExportUtil {
  static Future<void> exportAndShareRun(RunIsar run, List<RunPointIsar> points) async {
    final gpxXml = _generateGpxXml(run, points);
    
    // Generate a reasonable file name based on date and distance
    final dateStr = run.startTime != null 
        ? '${run.startTime!.year}${run.startTime!.month.toString().padLeft(2, '0')}${run.startTime!.day.toString().padLeft(2, '0')}'
        : 'unknown_date';
        
    final distanceKm = ((run.distanceM ?? 0) / 1000).toStringAsFixed(1);
    final fileName = 'trailhead_run_${distanceKm}km_$dateStr.gpx';

    // Write to temporary directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(gpxXml);

    // Share using share_plus
    await Share.shareXFiles([XFile(file.path)], text: 'My run on Trailhead ($distanceKm km)');
  }

  static String _generateGpxXml(RunIsar run, List<RunPointIsar> points) {
    final buffer = StringBuffer();
    
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Trailhead Mobile App" xmlns="http://www.topografix.com/GPX/1/1">');
    
    // Metadata
    buffer.writeln('  <metadata>');
    if (run.startTime != null) {
      buffer.writeln('    <time>${run.startTime!.toUtc().toIso8601String()}</time>');
    }
    buffer.writeln('  </metadata>');
    
    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${RunFormatUtils.getRunTitle(run.title, run.startTime, activityType: run.activityType ?? 'run')}</name>');
    buffer.writeln('    <trkseg>');
    
    // Points
    for (final p in points) {
      if (p.lat == null || p.lng == null) continue;
      
      buffer.writeln('      <trkpt lat="${p.lat}" lon="${p.lng}">');
      if (p.elevation != null) {
        buffer.writeln('        <ele>${p.elevation}</ele>');
      }
      if (p.timestamp != null) {
        buffer.writeln('        <time>${p.timestamp!.toUtc().toIso8601String()}</time>');
      }
      buffer.writeln('      </trkpt>');
    }
    
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    
    return buffer.toString();
  }
}

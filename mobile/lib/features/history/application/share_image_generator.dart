import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';

class ShareImageGenerator {
  static Future<void> generateAndShareImage(RunIsar run, List<LatLng> points) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1080, 1080);
    
    // 1. Draw Background
    final bgPaint = Paint()..color = const Color(0xFFE5E7EB); // Light gray matching screenshot
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (points.isNotEmpty) {
      // 2. Calculate Bounding Box
      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (var p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      
      // Calculate scaling
      const padding = 150.0;
      const bottomPadding = 350.0; // Extra room for stats
      final drawableWidth = size.width - padding * 2;
      final drawableHeight = size.height - padding - bottomPadding;
      
      final latRange = maxLat - minLat;
      final lngRange = maxLng - minLng;
      
      final scaleX = lngRange > 0 ? drawableWidth / lngRange : 1.0;
      final scaleY = latRange > 0 ? drawableHeight / latRange : 1.0;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      
      // Center offsets
      final offsetX = (size.width - (lngRange * scale)) / 2;
      final offsetY = (size.height - bottomPadding + padding - (latRange * scale)) / 2;

      // 3. Draw Polyline
      final path = ui.Path();
      bool first = true;
      for (var p in points) {
        // Simple scaling, invert lat because Canvas Y goes down, Lat goes up
        final x = offsetX + (p.longitude - minLng) * scale;
        final y = offsetY + (maxLat - p.latitude) * scale;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }

      final polylinePaint = Paint()
        ..color = const Color(0xFFFF5722) // Vibrant Orange
        ..strokeWidth = 14.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
        
      canvas.drawPath(path, polylinePaint);
    }

    // 4. Draw Gradient at the bottom
    const gradientHeight = 450.0;
    final gradientRect = Rect.fromLTWH(0, size.height - gradientHeight, size.width, gradientHeight);
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height - gradientHeight),
        Offset(0, size.height),
        [Colors.transparent, Colors.black.withOpacity(0.9)],
      );
    canvas.drawRect(gradientRect, gradientPaint);

    // 5. Draw Stats
    final distanceKm = ((run.distanceM ?? 0) / 1000).toStringAsFixed(2);
    final elevGain = (run.elevationGainM ?? 0).toStringAsFixed(0);
    final durationMins = ((run.durationS ?? 0) ~/ 60);
    final durationSecs = ((run.durationS ?? 0) % 60);
    final timeStr = "${durationMins}m ${durationSecs}s";

    _drawStatColumn(canvas, "Distance", "$distanceKm km", size.width * 0.22, size.height - 100);
    _drawStatColumn(canvas, "Elev Gain", "$elevGain m", size.width * 0.5, size.height - 100);
    _drawStatColumn(canvas, "Time", timeStr, size.width * 0.78, size.height - 100);

    // Finish Recording
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final buffer = byteData.buffer.asUint8List();

    // 6. Save and Share
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/activity_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);

    final xFile = XFile(file.path, mimeType: 'image/png');
    await Share.shareXFiles([xFile], text: 'Check out my activity on Trailhead!');
  }

  static void _drawStatColumn(Canvas canvas, String title, String value, double centerX, double bottomY) {
    // Value
    final valueSpan = TextSpan(
      text: value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 54,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter', // Try standard sans-serif
      ),
    );
    final valuePainter = TextPainter(
      text: valueSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    valuePainter.layout();

    // Title
    final titleSpan = TextSpan(
      text: title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    titlePainter.layout();

    final valueY = bottomY - valuePainter.height;
    final titleY = valueY - titlePainter.height - 10;

    titlePainter.paint(canvas, Offset(centerX - (titlePainter.width / 2), titleY));
    valuePainter.paint(canvas, Offset(centerX - (valuePainter.width / 2), valueY));
  }
}

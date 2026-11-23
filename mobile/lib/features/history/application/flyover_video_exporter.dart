import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_format_utils.dart';
import 'flyover_playback_controller.dart';

typedef ProgressCallback = void Function(double progress, String status);

/// Video resolution choices for 3D flyover export.
enum VideoRenderQuality {
  p720(
    width: 720,
    label: '720p HD',
    badge: '720p',
    subtitle: 'Faster render • Compact file size',
    bitrate: 2800000,
  ),
  p1080(
    width: 1080,
    label: '1080p Full HD',
    badge: '1080p',
    subtitle: 'Crisp detail • Best for Stories & Reels',
    bitrate: 5500000,
  );

  final int width;
  final String label;
  final String badge;
  final String subtitle;
  final int bitrate;

  const VideoRenderQuality({
    required this.width,
    required this.label,
    required this.badge,
    required this.subtitle,
    required this.bitrate,
  });
}

/// Exports the 3D Flyover animation as a hardware-accelerated H.264 MP4 video
/// and triggers the system share sheet.
class FlyoverVideoExporter {
  bool _isCancelled = false;

  void cancel() {
    _isCancelled = true;
  }

  Future<String?> recordAndExport({
    required GlobalKey repaintKey,
    required FlyoverPlaybackNotifier controller,
    required RunIsar run,
    required ProgressCallback onProgress,
    VideoRenderQuality quality = VideoRenderQuality.p720,
    int targetFps = 24,
    double videoDurationSeconds = 12.0,
  }) async {
    _isCancelled = false;
    controller.pause();

    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Recording boundary is not ready');
    }

    final totalFrames = (videoDurationSeconds * targetFps).round().clamp(60, 360);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/trailhead_flyover_$timestamp.mp4';

    // Measure widget dimensions and calculate scale ratio for target resolution
    final renderBox = repaintKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(360, 640);
    final scaleRatio = (quality.width / size.width).clamp(1.0, 3.5);

    // Initial capture to get exact pixel dimensions
    final initialImage = await boundary.toImage(pixelRatio: scaleRatio);
    final videoWidth = (initialImage.width ~/ 2) * 2;
    final videoHeight = (initialImage.height ~/ 2) * 2;
    initialImage.dispose();

    try {
      onProgress(0.0, 'Initializing video encoder (${quality.badge})...');
      await FlutterQuickVideoEncoder.setup(
        width: videoWidth,
        height: videoHeight,
        fps: targetFps,
        videoBitrate: quality.bitrate,
        profileLevel: ProfileLevel.any,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: outputPath,
      );

      for (int i = 0; i < totalFrames; i++) {
        if (_isCancelled) {
          try {
            await FlutterQuickVideoEncoder.finish();
            final file = File(outputPath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
          return null;
        }

        final t = i / (totalFrames - 1);
        controller.seek(t);

        // Allow Flutter to layout and paint the new frame deterministically
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 35));
        await WidgetsBinding.instance.endOfFrame;

        final ui.Image image = await boundary.toImage(pixelRatio: scaleRatio);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();

        if (byteData != null) {
          final rawBytes = byteData.buffer.asUint8List();
          await FlutterQuickVideoEncoder.appendVideoFrame(rawBytes);
        }

        final progressPct = (i + 1) / totalFrames;
        onProgress(progressPct, 'Rendering frame ${i + 1}/$totalFrames (${(progressPct * 100).toInt()}%)');
      }

      onProgress(1.0, 'Finalizing video...');
      await FlutterQuickVideoEncoder.finish();

      return outputPath;
    } catch (e) {
      try {
        await FlutterQuickVideoEncoder.finish();
      } catch (_) {}
      rethrow;
    }
  }

  /// Shares the generated video using SharePlus.
  static Future<void> shareVideo({
    required String filePath,
    required RunIsar run,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Video file not found at $filePath');
    }

    final title = RunFormatUtils.getRunTitle(
      run.title,
      run.startTime,
      activityType: run.activityType ?? 'run',
      distanceM: run.distanceM,
    );

    final xFile = XFile(filePath, mimeType: 'video/mp4');
    await Share.shareXFiles(
      [xFile],
      text: 'Reliving my $title with Trailhead 3D Flyover! 🏃‍♂️⛰️',
    );
  }
}

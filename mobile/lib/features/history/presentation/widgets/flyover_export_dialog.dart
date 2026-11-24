import 'package:trailhead_mobile/shared/navigation/app_navigator.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../audio/application/sound_service.dart';
import '../../../run_tracking/data/models/run_isar.dart';
import '../../application/flyover_playback_controller.dart';
import '../../application/flyover_video_exporter.dart';

/// Modal dialog allowing resolution selection (720p vs 1080p) and showing
/// live rendering progress when exporting a 3D Flyover video.
class FlyoverExportDialog extends ConsumerStatefulWidget {
  final GlobalKey repaintKey;
  final FlyoverPlaybackNotifier controller;
  final RunIsar run;

  const FlyoverExportDialog({
    super.key,
    required this.repaintKey,
    required this.controller,
    required this.run,
  });

  static Future<void> show({
    required BuildContext context,
    required GlobalKey repaintKey,
    required FlyoverPlaybackNotifier controller,
    required RunIsar run,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FlyoverExportDialog(
        repaintKey: repaintKey,
        controller: controller,
        run: run,
      ),
    );
  }

  @override
  ConsumerState<FlyoverExportDialog> createState() => _FlyoverExportDialogState();
}

class _FlyoverExportDialogState extends ConsumerState<FlyoverExportDialog> {
  final FlyoverVideoExporter _exporter = FlyoverVideoExporter();
  VideoRenderQuality _selectedQuality = VideoRenderQuality.p720;
  bool _isExporting = false;
  double _progress = 0.0;
  String _status = 'Preparing flyover video...';
  bool _isFinished = false;

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _status = 'Initializing ${_selectedQuality.badge} encoder...';
    });

    try {
      final outputPath = await _exporter.recordAndExport(
        repaintKey: widget.repaintKey,
        controller: widget.controller,
        run: widget.run,
        quality: _selectedQuality,
        onProgress: (prog, stat) {
          if (!mounted) return;
          setState(() {
            _progress = prog;
            _status = stat;
          });
        },
      );

      if (!mounted) return;

      if (outputPath != null) {
        _isFinished = true;
        AppNavigator.pop(context);
        await FlyoverVideoExporter.shareVideo(
          filePath: outputPath,
          run: widget.run,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppNavigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export video: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onCancel() {
    _exporter.cancel();
    if (mounted) {
      AppNavigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: retroColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: retroColors.border.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isExporting
                    ? _buildProgressView(retroColors)
                    : _buildQualitySelectorView(retroColors),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Initial screen where user selects 720p or 1080p resolution.
  Widget _buildQualitySelectorView(AppColors retroColors) {
    return Column(
      key: const ValueKey('quality_selector'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Icon
        Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: retroColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: retroColors.accent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                PhosphorIcons.videoCameraFill,
                color: retroColors.accent,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          'EXPORT 3D FLYOVER',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: retroColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Select video resolution for export',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: retroColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Quality Options List
        ...VideoRenderQuality.values.map((quality) {
          final isSelected = _selectedQuality == quality;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildQualityCard(quality, isSelected, retroColors),
          );
        }),

        const SizedBox(height: 10),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => AppNavigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: retroColors.border.withValues(alpha: 0.5)),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: retroColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startExport,
                icon: const Icon(PhosphorIcons.shareNetworkFill, size: 18),
                label: Text(
                  'Render & Share',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: retroColors.accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Individual Quality Selection Card (720p or 1080p).
  Widget _buildQualityCard(
    VideoRenderQuality quality,
    bool isSelected,
    AppColors retroColors,
  ) {
    return InkWell(
      onTap: () {
        ref.read(soundServiceProvider).playToggleSwitch();
        setState(() => _selectedQuality = quality);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? retroColors.accent.withValues(alpha: 0.12)
              : retroColors.surfaceRaised.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? retroColors.accent
                : retroColors.border.withValues(alpha: 0.5),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Custom Radio Indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? retroColors.accent : retroColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? retroColors.accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 13, color: Colors.black),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Quality Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        quality.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? retroColors.accent : retroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? retroColors.accent.withValues(alpha: 0.25)
                              : retroColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? retroColors.accent.withValues(alpha: 0.6)
                                : retroColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          quality.badge,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? retroColors.accent : retroColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    quality.subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: retroColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live Rendering & Encoding Progress View.
  Widget _buildProgressView(AppColors retroColors) {
    final pct = (_progress * 100).toInt().clamp(0, 100);

    return Column(
      key: const ValueKey('export_progress'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Header
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: retroColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: retroColors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.videoCameraFill,
              color: retroColors.accent,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'RENDERING ${_selectedQuality.badge}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: retroColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Status line
        Text(
          _status,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: retroColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Percentage display
        Text(
          '$pct%',
          style: GoogleFonts.barlowCondensed(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: retroColors.accent,
          ),
        ),
        const SizedBox(height: 12),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: retroColors.surfaceRaised,
            valueColor: AlwaysStoppedAnimation<Color>(retroColors.accent),
          ),
        ),
        const SizedBox(height: 24),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isFinished ? null : _onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: retroColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: retroColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

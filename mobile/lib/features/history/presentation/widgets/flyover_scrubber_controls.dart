import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/flyover_timeline_model.dart';
import '../../state_management/history_bloc_flyover_playback.dart';

/// Bottom glassmorphic playback control bar with interactive elevation scrubber,
/// speed selector, camera mode switcher, and audio feedback.
class FlyoverScrubberControls extends StatefulWidget {
  final FlyoverTimeline timeline;
  final FlyoverPlaybackState playbackState;
  final FlyoverPlaybackBloc controller;

  const FlyoverScrubberControls({
    super.key,
    required this.timeline,
    required this.playbackState,
    required this.controller,
  });

  @override
  State<FlyoverScrubberControls> createState() => _FlyoverScrubberControlsState();
}

class _FlyoverScrubberControlsState extends State<FlyoverScrubberControls> {
  bool _wasPlayingBeforeScrub = false;

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final progress = widget.playbackState.progress;
    final isPlaying = widget.playbackState.isPlaying;
    final speed = widget.playbackState.speedMultiplier;
    final cameraMode = widget.playbackState.cameraMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            decoration: BoxDecoration(
              color: retroColors.surface.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: retroColors.border.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Mini Elevation Profile & Scrubber (Line-only scrubber needle without dot)
                LayoutBuilder(
                  builder: (context, constraints) {
                    const hPadding = 12.0;
                    final totalWidth = constraints.maxWidth;
                    final usableWidth = (totalWidth - 2 * hPadding).clamp(1.0, double.infinity);

                    void seekToX(double localX) {
                      final clampedX = (localX - hPadding).clamp(0.0, usableWidth);
                      final seekProgress = (clampedX / usableWidth).clamp(0.0, 1.0);
                      widget.controller.seek(seekProgress);
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        _wasPlayingBeforeScrub = isPlaying;
                        if (isPlaying) {
                          widget.controller.pause();
                        }
                        seekToX(details.localPosition.dx);
                      },
                      onTapUp: (_) {
                        if (_wasPlayingBeforeScrub) {
                          widget.controller.play();
                        }
                      },
                      onTapCancel: () {
                        if (_wasPlayingBeforeScrub) {
                          widget.controller.play();
                        }
                      },
                      onHorizontalDragStart: (details) {
                        _wasPlayingBeforeScrub = isPlaying;
                        if (isPlaying) {
                          widget.controller.pause();
                        }
                        seekToX(details.localPosition.dx);
                      },
                      onHorizontalDragUpdate: (details) {
                        seekToX(details.localPosition.dx);
                      },
                      onHorizontalDragEnd: (_) {
                        if (_wasPlayingBeforeScrub) {
                          widget.controller.play();
                        }
                      },
                      onHorizontalDragCancel: () {
                        if (_wasPlayingBeforeScrub) {
                          widget.controller.play();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: retroColors.surfaceRaised.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: retroColors.border.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: hPadding),
                          child: SizedBox.expand(
                            child: CustomPaint(
                              size: Size(usableWidth, 52),
                              painter: _ElevationProfilePainter(
                                samples: widget.timeline.rawSamples,
                                minEle: widget.timeline.minElevationM,
                                maxEle: widget.timeline.maxElevationM,
                                progress: progress,
                                accentColor: retroColors.accent,
                                fillColor: retroColors.accent,
                                borderColor: retroColors.accent,
                                trackColor: retroColors.textSecondary.withValues(alpha: 0.30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // 2. Playback Control Bar
                Row(
                  children: [
                    // Speed multiplier button
                    _buildPillButton(
                      label: '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 1)}x',
                      icon: PhosphorIcons.lightning,
                      onTap: () => widget.controller.cycleSpeed(),
                      colors: retroColors,
                    ),

                    const Spacer(),

                    // Center Primary: Play / Pause and Rewind
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(PhosphorIcons.arrowCounterClockwise, color: retroColors.textSecondary, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Restart',
                          onPressed: () => widget.controller.restart(),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => widget.controller.togglePlay(),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: retroColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isPlaying ? PhosphorIcons.pauseFill : PhosphorIcons.playFill,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Camera Mode Switcher Dropdown Selector
                    _buildCameraModeDropdown(
                      currentMode: cameraMode,
                      onSelect: (mode) => widget.controller.setCameraMode(mode),
                      colors: retroColors,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceRaised.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraModeDropdown({
    required FlyoverCameraMode currentMode,
    required ValueChanged<FlyoverCameraMode> onSelect,
    required AppColors colors,
  }) {
    String currentLabel;
    IconData currentIcon;

    switch (currentMode) {
      case FlyoverCameraMode.perspective3D:
        currentLabel = '3D FLYOVER';
        currentIcon = PhosphorIcons.navigationArrowFill;
        break;
      case FlyoverCameraMode.chase3D:
        currentLabel = '3D CHASE';
        currentIcon = PhosphorIcons.compassFill;
        break;
      case FlyoverCameraMode.topDown2D:
        currentLabel = '2D FLAT';
        currentIcon = PhosphorIcons.mapTrifoldFill;
        break;
    }

    final modes = [
      (FlyoverCameraMode.perspective3D, '3D FLYOVER', PhosphorIcons.navigationArrowFill),
      (FlyoverCameraMode.chase3D, '3D CHASE', PhosphorIcons.compassFill),
      (FlyoverCameraMode.topDown2D, '2D FLAT', PhosphorIcons.mapTrifoldFill),
    ];

    return PopupMenuButton<FlyoverCameraMode>(
      tooltip: 'Select Camera Mode',
      initialValue: currentMode,
      position: PopupMenuPosition.over,
      offset: const Offset(0, -150),
      color: colors.surfaceRaised,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      onSelected: (mode) {
        if (mode != currentMode) {
          onSelect(mode);
        }
      },
      itemBuilder: (context) => modes.map((item) {
        final mode = item.$1;
        final label = item.$2;
        final icon = item.$3;
        final isSelected = mode == currentMode;

        return PopupMenuItem<FlyoverCameraMode>(
          value: mode,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.5,
                  color: isSelected ? colors.accent : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              if (isSelected)
                Icon(
                  PhosphorIcons.checkBold,
                  size: 13,
                  color: colors.accent,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceRaised.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentIcon, size: 14, color: colors.accent),
            const SizedBox(width: 5),
            Text(
              currentLabel,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              PhosphorIcons.caretDown,
              size: 11,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for mini elevation profile chart overlaid behind the scrubber.
class _ElevationProfilePainter extends CustomPainter {
  final List<FlyoverSample> samples;
  final double minEle;
  final double maxEle;
  final double progress;
  final Color accentColor;
  final Color fillColor;
  final Color borderColor;
  final Color trackColor;

  const _ElevationProfilePainter({
    required this.samples,
    required this.minEle,
    required this.maxEle,
    required this.progress,
    required this.accentColor,
    required this.fillColor,
    required this.borderColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final needleX = (progress.clamp(0.0, 1.0) * size.width).clamp(0.0, size.width);
    final baselineY = size.height * 0.80;

    // 1. Draw horizontal timeline track line (inactive track across full width)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), trackPaint);

    // Traveled horizontal timeline track line (accent color up to needleX)
    if (needleX > 0) {
      final activeTrackPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(0, baselineY), Offset(needleX, baselineY), activeTrackPaint);
    }

    // 2. Draw Elevation Profile Silhouette (if route samples available)
    if (samples.length >= 2) {
      final eleSpan = (maxEle - minEle).abs();
      final effectiveSpan = eleSpan > 1.5 ? eleSpan : 10.0;
      final isFlat = eleSpan <= 1.5;

      final path = Path();
      final fillPath = Path();

      for (int i = 0; i < samples.length; i++) {
        final s = samples[i];
        final x = (i / (samples.length - 1)) * size.width;
        final normalizedEle = isFlat
            ? 0.35
            : ((s.elevationM - minEle) / effectiveSpan).clamp(0.0, 1.0);
        // Map elevation nicely between 6px from top and baselineY
        final y = baselineY - (normalizedEle * (baselineY - 8));

        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, baselineY);
          fillPath.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }

      fillPath.lineTo(size.width, baselineY);
      fillPath.close();

      // Background elevation gradient fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withValues(alpha: 0.32),
            fillColor.withValues(alpha: 0.06),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, baselineY))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // Elevation outline stroke
      final linePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.4;
      canvas.drawPath(path, linePaint);
    }

    // 3. Draw vertical scrubber needle (clean luminous vertical line, NO dot)
    final needleGlow = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    canvas.drawLine(Offset(needleX, 4), Offset(needleX, size.height - 4), needleGlow);

    final needlePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(needleX, 4), Offset(needleX, size.height - 4), needlePaint);
  }

  @override
  bool shouldRepaint(covariant _ElevationProfilePainter old) {
    return old.progress != progress || old.samples.length != samples.length;
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../domain/flyover_timeline_model.dart';
import '../../state_management/history_bloc_flyover_playback.dart';

/// Map style choices available in the 3D Flyover view.
enum FlyoverMapStyle {
  standard,   // Grayscale OSM (retro athletic look)
  satellite,  // ESRI World Imagery
  terrain,    // ESRI Shaded Relief (natural shading + terrain)
}

extension FlyoverMapStyleExt on FlyoverMapStyle {
  String get label {
    switch (this) {
      case FlyoverMapStyle.standard:  return 'STANDARD';
      case FlyoverMapStyle.satellite: return 'SATELLITE';
      case FlyoverMapStyle.terrain:   return 'TERRAIN';
    }
  }
  IconData get icon {
    switch (this) {
      case FlyoverMapStyle.standard:  return PhosphorIcons.mapTrifold;
      case FlyoverMapStyle.satellite: return PhosphorIcons.globe;
      case FlyoverMapStyle.terrain:   return PhosphorIcons.mountains;
    }
  }
}

/// 3D Perspective Map Viewport for Flyover Route Animation.
///
/// Features:
/// - 3D Perspective matrix transformation (pitch & foreshortening).
/// - Dynamic camera follow with forward bearing alignment.
/// - Neon active route polyline vs. muted forward route polyline.
/// - Custom 3D Runner Avatar with directional heading cone and ground shadow.
/// - Milestone markers (1km, 2km...) along the trail.
/// - Atmospheric horizon depth gradient.
class Flyover3DMapView extends StatefulWidget {
  final FlyoverTimeline timeline;
  final FlyoverPlaybackState playbackState;
  final VoidCallback? onUserInteracted;

  const Flyover3DMapView({
    super.key,
    required this.timeline,
    required this.playbackState,
    this.onUserInteracted,
  });

  @override
  State<Flyover3DMapView> createState() => _Flyover3DMapViewState();
}

// Tile URL constants
const _kOsmUrl        = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _kEsriSatUrl    = 'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
const _kEsriTerrainUrl= 'https://services.arcgisonline.com/arcgis/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';

class _Flyover3DMapViewState extends State<Flyover3DMapView> {
  final MapController _mapController = MapController();
  bool _isFollowing = true;
  double _currentZoom = 16.5;
  double _smoothedBearing = 0.0;
  FlyoverMapStyle _mapStyle = FlyoverMapStyle.standard;
  bool _showStylePicker = false;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.timeline.baseZoom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateCamera(widget.playbackState.currentSample, immediate: true);
    });
  }

  void _updateCamera(FlyoverSample sample, {bool immediate = false}) {
    if (!_isFollowing) return;

    final targetBearing = widget.playbackState.cameraMode == FlyoverCameraMode.chase3D
        ? sample.bearing
        : 0.0;

    // Direct assignment because sample.bearing is already gimbal-smoothed
    _smoothedBearing = targetBearing;
    _currentZoom = sample.zoom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFollowing) return;
      try {
        _mapController.moveAndRotate(sample.point, _currentZoom, -_smoothedBearing);
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(covariant Flyover3DMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If playback is playing, always ensure camera following is active
    if (widget.playbackState.isPlaying) {
      _isFollowing = true;
    }

    final sample = widget.playbackState.currentSample;
    _updateCamera(sample);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void reCenter() {
    setState(() {
      _isFollowing = true;
    });
    _updateCamera(widget.playbackState.currentSample, immediate: true);
  }

  double _getTargetPitch(FlyoverCameraMode mode) {
    switch (mode) {
      case FlyoverCameraMode.perspective3D:
        return -0.45; // ~26 degrees forward 3D perspective tilt
      case FlyoverCameraMode.chase3D:
        return -0.45; // ~26 degrees forward 3D perspective tilt
      case FlyoverCameraMode.topDown2D:
        return 0.0; // Flat 0 degrees
    }
  }

  Widget _buildTileLayer(Brightness brightness) {
    switch (_mapStyle) {
      // ── SATELLITE ──────────────────────────────────────────────────────────
      case FlyoverMapStyle.satellite:
        return Stack(
          children: [
            TileLayer(
              urlTemplate: _kEsriSatUrl,
              maxNativeZoom: 18,
              maxZoom: 20,
              tileProvider: NetworkTileProvider(),
              userAgentPackageName: 'com.trailhead.mobile',
            ),
            // Semi-transparent OSM label overlay so route context is readable
            Opacity(
              opacity: 0.25,
              child: TileLayer(
                urlTemplate: _kOsmUrl,
                maxNativeZoom: 19,
                maxZoom: 20,
                tileProvider: NetworkTileProvider(),
                userAgentPackageName: 'com.trailhead.mobile',
              ),
            ),
          ],
        );

      // ── TERRAIN (ESRI World Topographic & Relief Shading) ──────────────────
      case FlyoverMapStyle.terrain:
        return TileLayer(
          urlTemplate: _kEsriTerrainUrl,
          maxNativeZoom: 17,
          maxZoom: 20,
          tileProvider: NetworkTileProvider(),
          userAgentPackageName: 'com.trailhead.mobile',
        );

      // ── STANDARD (Retro grayscale OSM) ─────────────────────────────────────
      case FlyoverMapStyle.standard:
        final tileLayer = TileLayer(
          urlTemplate: _kOsmUrl,
          maxNativeZoom: 19,
          maxZoom: 20,
          tileProvider: NetworkTileProvider(),
          userAgentPackageName: 'com.trailhead.mobile',
        );
        // Grayscale high-contrast filter
        const grayscaleMatrix = ColorFilter.matrix([
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0,     0,     0,     1, 0,
        ]);
        final greyed = ColorFiltered(colorFilter: grayscaleMatrix, child: tileLayer);
        if (brightness == Brightness.dark) {
          return ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1, 0, 0, 0, 255,
               0,-1, 0, 0, 255,
               0, 0,-1, 0, 255,
               0, 0, 0, 1,   0,
            ]),
            child: greyed,
          );
        }
        return greyed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final retroColors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;
    final progress = widget.playbackState.progress;
    final currentSample = widget.playbackState.currentSample;
    final timeline = widget.timeline;

    final traveledPoints = timeline.getTraveledPoints(progress);
    final remainingPoints = timeline.getRemainingPoints(progress);

    final targetPitch = _getTargetPitch(widget.playbackState.cameraMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        return Stack(
          children: [
            // 3D Perspective viewport container
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: targetPitch),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, pitch, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0010) // Smooth depth foreshortening
                      ..rotateX(pitch),        // Pitch tilt (negative = horizon at top, wide foreground at bottom)
                    child: child,
                  );
                },
                child: OverflowBox(
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: width * 1.5,
                  maxHeight: height * 1.5,
                  alignment: const Alignment(0.0, -0.35),
                  child: SizedBox(
                    width: width * 1.5,
                    height: height * 1.5,
                    child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentSample.point,
                      initialZoom: _currentZoom,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                      ),
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture && !widget.playbackState.isPlaying && _isFollowing) {
                          setState(() {
                            _isFollowing = false;
                          });
                          widget.onUserInteracted?.call();
                        }
                        _currentZoom = camera.zoom;
                      },
                    ),
                    children: [
                      _buildTileLayer(brightness),

                      // 1. Untraveled forward path (muted/dashed line)
                      if (remainingPoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: remainingPoints,
                              strokeWidth: 3.0,
                              color: retroColors.border.withValues(alpha: 0.5),
                            ),
                          ],
                        ),

                      // 2. Traveled neon path (vibrant illuminated accent)
                      if (traveledPoints.length >= 2) ...[
                        // Outer glow polyline
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: traveledPoints,
                              strokeWidth: 8.0,
                              color: retroColors.accent.withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                        // Inner solid polyline
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: traveledPoints,
                              strokeWidth: 4.5,
                              color: retroColors.accent,
                            ),
                          ],
                        ),
                      ],

                      // 3. Milestones (1 km, 2 km...)
                      MarkerLayer(
                        markers: timeline.milestones.map((m) {
                          final isPassed = m.progress <= progress;
                          return Marker(
                            point: m.point,
                            width: 50,
                            height: 24,
                            rotate: true,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? retroColors.surfaceRaised
                                    : retroColors.surface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isPassed
                                      ? retroColors.accent
                                      : retroColors.border.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                boxShadow: isPassed
                                    ? [
                                        BoxShadow(
                                          color: retroColors.accent.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  m.label,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPassed
                                        ? retroColors.textPrimary
                                        : retroColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // 4. Start Marker (App accent color)
                      if (timeline.fullRoutePoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: timeline.fullRoutePoints.first,
                              width: 24,
                              height: 24,
                              rotate: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: retroColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: retroColors.surface,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      // 5. Finish Marker (Checkerboard pattern matching run details)
                      if (timeline.fullRoutePoints.length > 1)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: timeline.fullRoutePoints.last,
                              width: 24,
                              height: 24,
                              rotate: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: retroColors.surface,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                child: const ClipOval(
                                  child: CustomPaint(
                                    size: Size(20, 20),
                                    painter: _CheckerboardPainter(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      // 6. Dynamic 3D Runner Avatar Marker (Clean flat puck)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentSample.point,
                            width: 28,
                            height: 28,
                            child: _Runner3DAvatar(
                              color: retroColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ),

            // Atmospheric horizon depth haze (subtle soft fade into 3D distance)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        retroColors.background.withValues(alpha: 0.35),
                        retroColors.background.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Map Controls Column: Re-Center Button + Map Style Selector Pill & Dropdown (Positioned at bottom above scrubber)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Re-Center Button (Visible when user has panned away)
                  if (!_isFollowing) ...[
                    FloatingActionButton.small(
                      heroTag: 'flyover_recenter_btn',
                      backgroundColor: retroColors.surfaceRaised,
                      foregroundColor: retroColors.accent,
                      elevation: 0,
                      onPressed: reCenter,
                      child: const Icon(PhosphorIcons.crosshair, size: 20),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Dropdown style options (Expands upward above the pill toggle)
                  if (_showStylePicker) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: retroColors.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: retroColors.border.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: FlyoverMapStyle.values.map((style) {
                              final isSelected = style == _mapStyle;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _mapStyle = style;
                                  _showStylePicker = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? retroColors.accent.withValues(alpha: 0.18)
                                        : Colors.transparent,
                                    border: style != FlyoverMapStyle.values.last
                                        ? Border(
                                            bottom: BorderSide(
                                              color: retroColors.border.withValues(alpha: 0.3),
                                              width: 0.5,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        style.icon,
                                        size: 14,
                                        color: isSelected ? retroColors.accent : retroColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        style.label,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? retroColors.textPrimary : retroColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Style pill toggle
                  GestureDetector(
                    onTap: () => setState(() => _showStylePicker = !_showStylePicker),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: retroColors.surface.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: retroColors.border.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_mapStyle.icon, size: 14, color: retroColors.accent),
                              const SizedBox(width: 5),
                              Text(
                                _mapStyle.label,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: retroColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showStylePicker ? PhosphorIcons.caretDown : PhosphorIcons.caretUp,
                                size: 11,
                                color: retroColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Clean runner position puck marker without forward pointer or shadows.
class _Runner3DAvatar extends StatelessWidget {
  final Color color;

  const _Runner3DAvatar({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3.5),
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering a classic racing finish line checkerboard pattern.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const divisions = 4;
    final cellW = size.width / divisions;
    final cellH = size.height / divisions;

    final paintLight = Paint()..color = Colors.white;
    final paintDark = Paint()..color = Colors.black;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintLight);

    for (int row = 0; row < divisions; row++) {
      for (int col = 0; col < divisions; col++) {
        if ((row + col) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH),
            paintDark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}

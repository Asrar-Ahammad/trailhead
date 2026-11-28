import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/theme/app_colors.dart';
import 'package:trailhead_mobile/features/run_tracking/domain/run_tracking_use_case_calculations.dart';

/// Static, read-only route map shown after a run is completed.
///
/// Renders the full route polyline, Strava-style kilometer/milestone markers,
/// green start marker, and coral finish flag.
///
/// [points] must be in chronological order (start → end).
class StaticRouteMap extends StatelessWidget {
  const StaticRouteMap({
    super.key,
    required this.points,
    this.showBaseMap = true,
    this.showMarkers = true,
    this.showKilometerMarkers = true,
    this.useMiles = false,
    this.padding = const EdgeInsets.all(32.0),
    this.animationProgress,
    this.isMonochrome = false,
  });

  final List<LatLng> points;
  final bool showBaseMap;
  final bool showMarkers;
  final bool showKilometerMarkers;
  final bool useMiles;
  final EdgeInsets padding;
  final double? animationProgress;
  final bool isMonochrome;

  // Single free OSM tile URL — no API key needed.
  static const String _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Builds the tile layer with optional monochrome (grayscale) or dark mode filtering.
  Widget _buildTileLayer(Brightness brightness) {
    final tileLayer = TileLayer(
      urlTemplate: _osmTileUrl,
      tileProvider: NetworkTileProvider(),
      userAgentPackageName: 'com.trailhead.mobile',
    );

    if (isMonochrome) {
      if (brightness == Brightness.dark) {
        // High-contrast dark monochrome (grayscale inverted)
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -0.2126, -0.7152, -0.0722, 0, 240,
            -0.2126, -0.7152, -0.0722, 0, 240,
            -0.2126, -0.7152, -0.0722, 0, 240,
             0,       0,       0,      1, 0,
          ]),
          child: tileLayer,
        );
      } else {
        // Crisp light grayscale monochrome
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: tileLayer,
        );
      }
    }

    if (brightness == Brightness.dark) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]),
        child: tileLayer,
      );
    }
    return tileLayer;
  }


  /// Computes a [LatLngBounds] that fits all [points] with padding.
  /// Returns null if there are fewer than 2 distinct points (zero-area bounds
  /// would cause an infinite zoom crash in flutter_map).
  LatLngBounds? _fitBounds() {
    if (points.length < 2) return null;
    final bounds = LatLngBounds.fromPoints(points);
    // Guard against zero-area bounds (all points identical)
    if (bounds.north == bounds.south && bounds.east == bounds.west) return null;
    return bounds;
  }

  /// Calculates exact milestone coordinates along the path (e.g. 1 km, 2 km...).
  List<_MilestonePoint> _calculateMilestones(List<LatLng> pts) {
    if (pts.length < 2) return const [];
    final intervalM = useMiles ? 1609.344 : 1000.0;
    final milestones = <_MilestonePoint>[];
    double accumulatedM = 0.0;
    int nextMilestone = 1;

    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final dist = TrackingCalcs.calculateDistance(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      final nextTargetM = nextMilestone * intervalM;
      if (accumulatedM + dist >= nextTargetM) {
        final excess = nextTargetM - accumulatedM;
        final fraction = (dist > 0.001) ? (excess / dist).clamp(0.0, 1.0) : 0.0;
        final lat = prev.latitude + (curr.latitude - prev.latitude) * fraction;
        final lng = prev.longitude + (curr.longitude - prev.longitude) * fraction;

        milestones.add(_MilestonePoint(
          number: nextMilestone,
          point: LatLng(lat, lng),
        ));
        nextMilestone++;
      }
      accumulatedM += dist;
    }
    return milestones;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;

    if (points.isEmpty) {
      return _EmptyMapPlaceholder(colors: colors);
    }

    final bounds = _fitBounds();
    final center = bounds != null
        ? LatLng(
            (bounds.north + bounds.south) / 2,
            (bounds.east + bounds.west) / 2,
          )
        : points.first;

    List<LatLng> renderPoints = points;
    if (animationProgress != null) {
      final pointsToShow = (points.length * animationProgress!).ceil().clamp(1, points.length);
      renderPoints = points.sublist(0, pointsToShow);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: bounds != null
              ? CameraFit.bounds(
                  bounds: bounds,
                  padding: padding,
                )
              : null,
          initialCenter: center,
          initialZoom: 15.0, // used when bounds is null (single/identical points)
          backgroundColor: Colors.transparent,
          interactionOptions: const InteractionOptions(
            // Read-only — disable all gestures on the static map
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          if (showBaseMap)
            _buildTileLayer(brightness),


          // Full route polyline
          if (renderPoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: renderPoints,
                  strokeWidth: 3.5,
                  color: colors.accent,
                ),
              ],
            ),

          // Strava-style kilometer / milestone markers along route polyline
          if (showMarkers && showKilometerMarkers)
            MarkerLayer(
              markers: [
                ..._calculateMilestones(renderPoints).map(
                  (m) => Marker(
                    point: m.point,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.textPrimary,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${m.number}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Start marker (Green circle with white inner dot)
          if (showMarkers)
            MarkerLayer(
              markers: [
                Marker(
                  point: renderPoints.first,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surface,
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

          // End marker (Checkerboard finish pattern)
          if (showMarkers && renderPoints.length > 1 && (animationProgress == null || animationProgress! >= 1.0))
            MarkerLayer(
              markers: [
                Marker(
                  point: renderPoints.last,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surface,
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

          if (showBaseMap)
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
              showFlutterMapAttribution: false,
            ),
        ],
      ),
    );
  }
}

/// Shown when no GPS points are available (e.g. treadmill run, GPS denied).
class _EmptyMapPlaceholder extends StatelessWidget {
  const _EmptyMapPlaceholder({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        'No route recorded',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _MilestonePoint {
  final int number;
  final LatLng point;

  const _MilestonePoint({
    required this.number,
    required this.point,
  });
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

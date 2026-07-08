import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/map_tile_cache_manager.dart';
import '../../../../shared/theme/app_colors.dart';

/// Static, read-only route map shown after a run is completed.
///
/// Renders the full route polyline, a green start marker, and a coral/red end
/// marker. Used on the post-run completion screen (Phase 3).
///
/// [points] must be in chronological order (start → end).
class StaticRouteMap extends StatelessWidget {
  const StaticRouteMap({
    super.key,
    required this.points,
  });

  final List<LatLng> points;

  String _tileUrl(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png';
    }
    return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
  }

  /// Computes a [LatLngBounds] that fits all [points] with padding.
  LatLngBounds? _fitBounds() {
    if (points.isEmpty) return null;
    return LatLngBounds.fromPoints(points);
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14.0,
          interactionOptions: const InteractionOptions(
            // Read-only — disable all gestures on the static map
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: _tileUrl(brightness),
            subdomains: const ['a', 'b', 'c'],
            tileProvider: MapTileCacheManager.instance.tileProvider,
            userAgentPackageName: 'com.trailhead.mobile',
          ),

          // Full route polyline
          if (points.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 3.5,
                  color: colors.accent,
                ),
              ],
            ),

          // Start marker — green
          CircleLayer(
            circles: [
              CircleMarker(
                point: points.first,
                radius: 8,
                color: colors.success,
                borderColor: Colors.white,
                borderStrokeWidth: 2,
              ),
            ],
          ),

          // End marker — coral/accent
          if (points.length > 1)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: points.last,
                  radius: 8,
                  color: colors.accent,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('\u00a9 OpenStreetMap contributors'),
              TextSourceAttribution('\u00a9 CARTO'),
            ],
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../application/route_provider.dart';
import '../../data/map_tile_cache_manager.dart';
import '../../../../shared/theme/app_colors.dart';

/// Live map widget rendered during an active run (foreground only).
///
/// Shows a CartoDB tile layer (dark in dark theme, light in light theme),
/// a polyline of all accepted GPS points so far, and a circle marker at the
/// current position. The camera follows the latest point automatically.
class LiveRunMap extends ConsumerStatefulWidget {
  const LiveRunMap({super.key});

  @override
  ConsumerState<LiveRunMap> createState() => _LiveRunMapState();
}

class _LiveRunMapState extends ConsumerState<LiveRunMap> {
  final MapController _mapController = MapController();

  // Default center: shows world overview before any GPS fix
  static const LatLng _defaultCenter = LatLng(20.0, 0.0);
  static const double _runningZoom = 16.5;
  static const double _defaultZoom = 2.0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _tileUrl(Brightness brightness) {
    // CartoDB dark tiles in dark mode, light tiles in light mode.
    // Same tile provider as original web plan — visual continuity per spec.
    if (brightness == Brightness.dark) {
      return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png';
    }
    return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
  }

  void _followLatestPoint(List<LatLng> points) {
    if (points.isEmpty) return;
    final latest = points.last;
    _mapController.move(latest, _runningZoom);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;
    final routeAsync = ref.watch(routePointsProvider);

    final points = routeAsync.valueOrNull ?? [];

    // Follow latest point whenever it changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followLatestPoint(points);
    });

    final initialCenter = points.isNotEmpty ? points.last : _defaultCenter;
    final initialZoom = points.isNotEmpty ? _runningZoom : _defaultZoom;

    return ClipRect(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // Tile layer with session caching
          TileLayer(
            urlTemplate: _tileUrl(brightness),
            subdomains: const ['a', 'b', 'c'],
            tileProvider: MapTileCacheManager.instance.tileProvider,
            userAgentPackageName: 'com.trailhead.mobile',
          ),

          // Route polyline
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

          // Current position dot
          if (points.isNotEmpty)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: points.last,
                  radius: 8,
                  color: colors.success.withValues(alpha: 0.9),
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

          // Attribution — required per CartoDB/OSM terms
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '\u00a9 OpenStreetMap contributors',
              ),
              TextSourceAttribution(
                '\u00a9 CARTO',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

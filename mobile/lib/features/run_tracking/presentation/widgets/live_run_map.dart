import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../application/route_provider.dart';
import '../../application/run_tracker_controller.dart';
import '../../data/map_tile_cache_manager.dart';
import '../../../../shared/theme/app_colors.dart';

/// Live map widget rendered during an active run (foreground only).
///
/// Shows a CartoDB tile layer (dark in dark theme, light in light theme),
/// a polyline of all accepted GPS points so far, and a circle marker at the
/// current position. The camera follows the latest point automatically.
class LiveRunMap extends ConsumerStatefulWidget {
  final LatLng? initialLocation;

  const LiveRunMap({super.key, this.initialLocation});

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
  void didUpdateWidget(LiveRunMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation && widget.initialLocation != null) {
      final points = ref.read(routePointsProvider).valueOrNull ?? [];
      if (points.isEmpty) {
        _mapController.move(widget.initialLocation!, _runningZoom);
      }
    }
  }

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

    final initialCenter = points.isNotEmpty 
        ? points.last 
        : (widget.initialLocation ?? _defaultCenter);
        
    final initialZoom = (points.isNotEmpty || widget.initialLocation != null) 
        ? _runningZoom 
        : _defaultZoom;

    return ClipRect(
      child: Stack(
        children: [
          FlutterMap(
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

              const RichAttributionWidget(
                attributions: [],
                showFlutterMapAttribution: false,
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
              if (points.isNotEmpty || widget.initialLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: points.isNotEmpty ? points.last : widget.initialLocation!,
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
          
          // Manual location fetch button
          Positioned(
            right: 16,
            bottom: 32, // above attribution
            child: FloatingActionButton(
              heroTag: 'manual_location',
              mini: true,
              backgroundColor: colors.surfaceRaised,
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                    timeLimit: const Duration(seconds: 10),
                  );
                  ref.read(runTrackerProvider.notifier).updateInitialPosition(pos);
                  _mapController.move(LatLng(pos.latitude, pos.longitude), _runningZoom);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not fetch location')),
                    );
                  }
                }
              },
              child: Icon(PhosphorIcons.navigationArrow(PhosphorIconsStyle.fill), color: colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

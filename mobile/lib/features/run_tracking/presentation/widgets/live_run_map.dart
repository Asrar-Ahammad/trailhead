import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_route_map.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import '../../../../shared/theme/app_colors.dart';
import 'location_markers.dart';

/// Live map widget rendered during an active run (foreground only).
///
/// Two visual states:
///   * **Locating** – full-canvas radar sweep while GPS fix is pending.
///   * **Located**  – static two-ring dot on the user's exact position.
class LiveRunMap extends StatefulWidget {
  final LatLng? initialLocation;

  const LiveRunMap({super.key, this.initialLocation});

  @override
  State<LiveRunMap> createState() => _LiveRunMapState();
}

class _LiveRunMapState extends State<LiveRunMap> {
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(20.0, 0.0);
  static const double _runningZoom = 18.0;
  static const double _defaultZoom = 2.0;
  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Last position the camera was centered on.
  /// Used to detect when position changes so we can re-center.
  LatLng? _lastCenteredAt;

  /// Falls to true after 12 s to guarantee the locating overlay is
  /// always dismissed even when GPS is completely unavailable.
  bool _locationTimedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fetch a fresh GPS fix immediately on screen open.
      context.read<RunTrackerCubit>().fetchInitialLocation();

      // If position was already known from app startup, center now.
      _centerIfNewPosition(_currentPosition());
    });

    // Safety net: after 12 s, force the locating overlay off regardless of
    // whether GPS resolved. This prevents the radar from showing forever
    // in GPS-denied environments (indoors, airplane mode, simulator).
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !_locationTimedOut) {
        setState(() => _locationTimedOut = true);
      }
    });
  }

  /// Returns the best available position: route points > tracker state > widget prop.
  LatLng? _currentPosition() {
    final points = context.read<RunRouteMapCubit>().state.points;
    if (points.isNotEmpty) return points.last;
    final pos = context.read<RunTrackerCubit>().state.initialPosition;
    if (pos != null) return LatLng(pos.latitude, pos.longitude);
    return widget.initialLocation;
  }

  /// Moves the camera to [pos] if it differs from the last centered position.
  void _centerIfNewPosition(LatLng? pos) {
    if (pos == null) return;
    if (_lastCenteredAt == pos) return;
    _lastCenteredAt = pos;
    try {
      _mapController.move(pos, _runningZoom);
    } catch (_) {
      // Controller not ready yet — will be handled on next rebuild.
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Widget _buildTileLayer(Brightness brightness) {
    final tileLayer = TileLayer(
      urlTemplate: _osmTileUrl,
      tileProvider: NetworkTileProvider(),
      userAgentPackageName: 'com.trailhead.mobile',
    );

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

  @override
  Widget build(BuildContext context) => BlocListener<RunRouteMapCubit, RunRouteMapState>(
    listenWhen: (before, after) => before.recenterVersion != after.recenterVersion,
    listener: (context, _) => _recenter(),
    child: Builder(builder: _buildMap),
  );

  void _recenter() {
    _lastCenteredAt = null;
    final position = _currentPosition();
    if (position == null) return;
    try {
      _mapController.move(position, _runningZoom);
      _lastCenteredAt = position;
    } catch (_) {
      // The map may still be attaching during a tab change.
    }
  }

  Widget _buildMap(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final brightness = Theme.of(context).brightness;
    final points = context.select((RunRouteMapCubit cubit) => cubit.state.points);
    final trackerState = context.watch<RunTrackerCubit>().state;


    // ── Derive the current user position ──────────────────────────────────
    // Priority: live GPS route > initialPosition from state > widget prop.
    final trackerPos = trackerState.initialPosition;
    final LatLng? livePosition = points.isNotEmpty
        ? points.last
        : (trackerPos != null
            ? LatLng(trackerPos.latitude, trackerPos.longitude)
            : widget.initialLocation);

    // ── Camera control ────────────────────────────────────────────────────
    // During a run: follow the latest GPS point every frame.
    // Pre-run: center once whenever position changes (first fix or manual refresh).
    if (points.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(points.last, _runningZoom);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerIfNewPosition(livePosition);
      });
    }

    final initialCenter = livePosition ?? _defaultCenter;
    final initialZoom = livePosition != null ? _runningZoom : _defaultZoom;

    // Show the locating overlay only when permissions are confirmed and granted, but fix is still pending.
    // Also hides after 12 s regardless (safety timeout for GPS-denied environments).
    final isLocating = !_locationTimedOut &&
        trackerState.permissionsChecked &&
        trackerState.permissionsGranted &&
        livePosition == null;
    final isLocated = livePosition != null;

    return ClipRect(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              // Prevent zooming out to world-wrap level (which duplicates
              // markers) and zooming too far in past useful detail.
              minZoom: 3.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                // Disable rotation — it has no use case here and causes the
                // confusing tilted-world view visible in the screenshot.
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              _buildTileLayer(brightness),

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

              // Located marker — static dot, no animation
              if (isLocated)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: livePosition,
                      width: 24,
                      height: 24,
                      child: LocatedMarker(color: colors.accent),
                    ),
                  ],
                ),

              // Attribution — required per OSM/Stadia terms
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('\u00a9 OpenStreetMap contributors'),
                  TextSourceAttribution('\u00a9 Stadia Maps'),
                ],
              ),
            ],
          ),

          // ── LOCATING OVERLAY ─────────────────────────────────────────────
          // Full-canvas radar sweep while GPS fix is pending.
          // Fades out smoothly (700 ms) once a position is acquired.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            opacity: isLocating ? 1.0 : 0.0,
            child: IgnorePointer(
              child: LocatingOverlay(color: colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

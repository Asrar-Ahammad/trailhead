import '../../run_tracking/data/models/run_point_isar.dart';
import '../domain/history_use_case_route_analytics.dart';

RouteMetricPoint toRouteMetricPoint(RunPointIsar point) => (
  lat: point.lat,
  lng: point.lng,
  timestamp: point.timestamp,
  speed: point.speed,
  elevation: point.elevation,
  cadence: point.cadence,
  isPaused: point.isPaused,
);

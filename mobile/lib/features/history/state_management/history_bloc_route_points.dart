import 'package:latlong2/latlong.dart';
import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../../run_tracking/data/models/run_point_isar.dart';

typedef CreateHistoryRouteBloc = HistoryRouteBloc Function(String? runId);

class HistoryRouteBloc extends AsyncResourceBloc<List<RunPointIsar>> {
  HistoryRouteBloc(this.runId, this.read) {
    add(LoadResource(load));
  }

  final String? runId;
  final Future<List<RunPointIsar>> Function(String) read;

  Future<List<RunPointIsar>> load() async {
    final id = runId;
    return state.valueOrNull ?? (id == null ? const [] : await read(id));
  }

  static List<LatLng> coordinates(Iterable<RunPointIsar> points) => points
      .where((point) => point.lat != null && point.lng != null)
      .map((point) => LatLng(point.lat!, point.lng!))
      .toList(growable: false);
}

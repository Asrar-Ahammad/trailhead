import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

typedef RunRouteMapState = ({List<LatLng> points, int recenterVersion});

class RunRouteMapCubit extends Cubit<RunRouteMapState> {
  RunRouteMapCubit(Stream<List<LatLng>> routes)
    : super((points: const [], recenterVersion: 0)) {
    _subscription = routes.listen(
      (points) =>
          emit((points: points, recenterVersion: state.recenterVersion)),
      onError: (Object error, StackTrace trace) => addError(error, trace),
    );
  }

  late final StreamSubscription<List<LatLng>> _subscription;

  void recenter() =>
      emit((points: state.points, recenterVersion: state.recenterVersion + 1));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}

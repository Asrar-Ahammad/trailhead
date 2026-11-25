import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide distance preference shared by run, history, and stats features.
class DistanceUnitCubit extends Cubit<bool> {
  DistanceUnitCubit({bool useMiles = false}) : super(useMiles);

  void setUseMiles(bool useMiles) {
    // Miles are currently disabled by product behavior in the existing app.
    emit(false);
  }
}

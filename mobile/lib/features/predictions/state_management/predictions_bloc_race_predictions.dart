import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/state_management/async_value.dart';
import '../domain/predictions_entity_race_predictions.dart';
import '../domain/predictions_use_case_load_race_predictions.dart';

typedef CreatePredictionsBloc = PredictionsBloc Function();

class PredictionsRequested {
  const PredictionsRequested();
}

class PredictionsBloc
    extends Bloc<PredictionsRequested, AsyncValue<RacePredictions?>> {
  PredictionsBloc(this._loadPredictions) : super(const AsyncValue.loading()) {
    on<PredictionsRequested>(_load);
  }

  final LoadRacePredictions _loadPredictions;

  Future<void> _load(
    PredictionsRequested event,
    Emitter<AsyncValue<RacePredictions?>> emit,
  ) async {
    try {
      emit(AsyncValue.data(await _loadPredictions()));
    } catch (error, stackTrace) {
      emit(AsyncValue.error(error, stackTrace));
    }
  }
}

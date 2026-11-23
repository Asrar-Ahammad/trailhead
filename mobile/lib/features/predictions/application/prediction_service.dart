import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';
import '../../../shared/state/app_cubits.dart';

class PredictionService {
  final ApiClient _apiClient;
  
  PredictionService(this._apiClient);

  Future<Map<String, dynamic>> getPredictions() async {
    final client = _apiClient.client;
    final response = await client.get('/predictions');
    return response.data;
  }
}

class PredictionsCubit extends Cubit<AsyncState<Map<String, dynamic>>> {
  PredictionsCubit({required PredictionService service})
      : _service = service,
        super(const AsyncState.loading()) {
    load();
  }

  final PredictionService _service;

  Future<void> load() async {
    emit(const AsyncState.loading());
    try {
      emit(AsyncState.data(await _service.getPredictions()));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService(ref);
});

final racePredictionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(predictionServiceProvider);
  return await service.getPredictions();
});

class PredictionService {
  final Ref _ref;
  
  PredictionService(this._ref);

  Future<Map<String, dynamic>> getPredictions() async {
    final client = _ref.read(apiClientProvider).client;
    final response = await client.get('/predictions');
    return response.data;
  }
}

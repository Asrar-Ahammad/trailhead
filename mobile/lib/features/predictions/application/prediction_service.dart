import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/shared/network/api_client.dart';
import 'package:trailhead_mobile/features/auth/application/auth_service.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return PredictionService(auth);
});

final racePredictionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(predictionServiceProvider);
  return await service.getPredictions();
});

class PredictionService {
  final AuthService _authService;
  
  PredictionService(this._authService);

  Future<Map<String, dynamic>> getPredictions() async {
    final dio = _authService.authenticatedDio;
    final response = await dio.get('/predictions');
    return response.data;
  }
}

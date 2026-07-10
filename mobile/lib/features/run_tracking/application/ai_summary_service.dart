import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/models/run_isar.dart';
import '../../sync/data/api_client.dart';

final aiSummaryProvider = FutureProvider.family<String, RunIsar>((ref, run) async {
  final apiClient = ref.read(apiClientProvider);
  
  try {
    final response = await apiClient.client.post(
      '/runs/summary',
      data: {
        'distanceM': run.distanceM,
        'durationS': run.durationS,
        'avgPaceSPerKm': run.avgPaceSPerKm,
        'caloriesKcal': run.caloriesKcal,
        'avgStrideLengthM': run.avgStrideLengthM,
        'avgCadenceSpm': run.avgCadenceSpm,
        // timeOfDay could be added here based on run.startTime
      },
    );
    
    if (response.statusCode == 200 && response.data['summary'] != null) {
      return response.data['summary'] as String;
    }
  } catch (e) {
    // Graceful fallback on API failure
    print('Failed to fetch AI summary: $e');
  }

  // Fallback text if the API fails or doesn't return the expected format
  return 'Great effort out there! Keep stacking those miles.';
});

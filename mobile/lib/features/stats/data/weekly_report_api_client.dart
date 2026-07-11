import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/sync/data/api_client.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';

final weeklyReportApiClientProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WeeklyReportApiClient(apiClient.client);
});

final weeklyReportsProvider = FutureProvider<List<WeeklyReportModel>>((ref) async {
  final client = ref.watch(weeklyReportApiClientProvider);
  await client.syncWeeklyReports(); // Ensure latest runs are grouped and saved
  return client.getWeeklyReportsHistory();
});

class WeeklyReportApiClient {
  final Dio _dio;

  WeeklyReportApiClient(this._dio);

  Future<void> syncWeeklyReports() async {
    try {
      await _dio.post('/summary/weekly/sync');
    } catch (e) {
      print('Failed to sync weekly reports: $e');
      // Non-fatal, just log it. The history endpoint will return what's available.
    }
  }

  Future<List<WeeklyReportModel>> getWeeklyReportsHistory() async {
    try {
      final response = await _dio.get('/summary/weekly/history');
      if (response.statusCode == 200) {
        final List<dynamic> reportsData = response.data['reports'];
        return reportsData.map((e) => WeeklyReportModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Failed to get weekly reports history: $e');
      return [];
    }
  }
}

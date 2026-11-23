import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:trailhead_mobile/features/stats/data/models/weekly_report_model.dart';
import '../../../shared/state/app_cubits.dart';

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

class WeeklyReportsCubit extends Cubit<AsyncState<List<WeeklyReportModel>>> {
  WeeklyReportsCubit({required WeeklyReportApiClient client})
      : _client = client,
        super(const AsyncState.loading()) {
    load();
  }

  final WeeklyReportApiClient _client;

  Future<void> load() async {
    emit(const AsyncState.loading());
    try {
      await _client.syncWeeklyReports();
      emit(AsyncState.data(await _client.getWeeklyReportsHistory()));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/state/app_cubits.dart';
import '../../stats/application/pr_engine.dart';
import '../../sync/data/api_client.dart';
import '../data/models/run_isar.dart';

class PostRunSummaryState {
  const PostRunSummaryState({
    this.aiSummary = const AsyncState.loading(),
    this.isNewPr = const AsyncState.loading(),
  });

  final AsyncState<String> aiSummary;
  final AsyncState<bool> isNewPr;

  PostRunSummaryState copyWith({
    AsyncState<String>? aiSummary,
    AsyncState<bool>? isNewPr,
  }) => PostRunSummaryState(
    aiSummary: aiSummary ?? this.aiSummary,
    isNewPr: isNewPr ?? this.isNewPr,
  );
}

class PostRunSummaryCubit extends Cubit<PostRunSummaryState> {
  PostRunSummaryCubit({
    required RunIsar run,
    required ApiClient apiClient,
    required PREngine engine,
  }) : _run = run,
       _apiClient = apiClient,
       _engine = engine,
       super(const PostRunSummaryState()) {
    load();
  }

  final RunIsar _run;
  final ApiClient _apiClient;
  final PREngine _engine;

  Future<void> load() async {
    await Future.wait([_loadSummary(), _loadPr()]);
  }

  Future<void> _loadSummary() async {
    try {
      final response = await _apiClient.client.post(
        '/runs/summary',
        data: {
          'distanceM': _run.distanceM,
          'durationS': _run.durationS,
          'avgPaceSPerKm': _run.avgPaceSPerKm,
          'caloriesKcal': _run.caloriesKcal,
          'avgStrideLengthM': _run.avgStrideLengthM,
          'avgCadenceSpm': _run.avgCadenceSpm,
        },
      );
      final summary =
          response.statusCode == 200 && response.data['summary'] != null
          ? response.data['summary'] as String
          : 'Great effort out there! Keep stacking those miles.';
      emit(state.copyWith(aiSummary: AsyncState.data(summary)));
    } catch (_) {
      emit(
        state.copyWith(
          aiSummary: const AsyncState.data(
            'Great effort out there! Keep stacking those miles.',
          ),
        ),
      );
    }
  }

  Future<void> _loadPr() async {
    try {
      if (_run.clientRunId == null) {
        emit(state.copyWith(isNewPr: const AsyncState.data(false)));
        return;
      }
      final records = await _engine.getRecords();
      final isNewPr = records.bestEffort.any(
        (record) => record.runId == _run.clientRunId,
      );
      emit(state.copyWith(isNewPr: AsyncState.data(isNewPr)));
    } catch (error, stackTrace) {
      emit(state.copyWith(isNewPr: AsyncState.error(error, stackTrace)));
    }
  }
}

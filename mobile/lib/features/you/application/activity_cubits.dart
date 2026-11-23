import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/state/app_cubits.dart';
import '../../history/data/run_history_repository.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../stats/application/pr_engine.dart';
import '../../stats/data/models/weekly_report_model.dart';

class CompletedRunsCubit extends Cubit<AsyncState<List<RunIsar>>> {
  CompletedRunsCubit({required RunHistoryRepository repository})
    : _repository = repository,
      super(const AsyncState.loading()) {
    _subscription = repository.watchCompletedRuns().listen(
      (runs) => emit(AsyncState.data(runs)),
      onError: (Object error, StackTrace stackTrace) =>
          emit(AsyncState.error(error, stackTrace)),
    );
  }

  final RunHistoryRepository _repository;
  StreamSubscription<List<RunIsar>>? _subscription;

  Future<void> refresh() async {
    try {
      emit(AsyncState.data(await _repository.getCompletedRuns()));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}

class PersonalRecordsCubit extends Cubit<AsyncState<RecordGroup>> {
  PersonalRecordsCubit({required PREngine engine})
    : _engine = engine,
      super(const AsyncState.loading()) {
    load();
  }

  final PREngine _engine;

  Future<void> load() async {
    emit(const AsyncState.loading());
    try {
      emit(AsyncState.data(await _engine.getRecords()));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}

class WeeklyRunsState {
  const WeeklyRunsState({this.reports = const {}});
  final Map<String, AsyncState<List<RunIsar>>> reports;

  String keyFor(WeeklyReportModel report) =>
      '${report.startDate.toIso8601String()}|${report.endDate.toIso8601String()}';
  AsyncState<List<RunIsar>> forReport(WeeklyReportModel report) =>
      reports[keyFor(report)] ?? const AsyncState.loading();
}

class WeeklyRunsCubit extends Cubit<WeeklyRunsState> {
  WeeklyRunsCubit({required RunHistoryRepository repository})
    : _repository = repository,
      super(const WeeklyRunsState());

  final RunHistoryRepository _repository;
  final Map<String, StreamSubscription<List<RunIsar>>> _subscriptions = {};

  void observe(WeeklyReportModel report) {
    final key = state.keyFor(report);
    if (state.reports.containsKey(key)) return;
    emit(
      WeeklyRunsState(
        reports: {...state.reports, key: const AsyncState.loading()},
      ),
    );
    _subscriptions[key] = _repository.watchCompletedRuns().listen(
      (runs) {
        final weekRuns = runs.where((run) {
          final startTime = run.startTime;
          return startTime != null &&
              !startTime.isBefore(report.startDate) &&
              startTime.isBefore(report.endDate.add(const Duration(days: 1)));
        }).toList()..sort((a, b) => b.startTime!.compareTo(a.startTime!));
        emit(
          WeeklyRunsState(
            reports: {...state.reports, key: AsyncState.data(weekRuns)},
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          WeeklyRunsState(
            reports: {
              ...state.reports,
              key: AsyncState.error(error, stackTrace),
            },
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    await super.close();
  }
}

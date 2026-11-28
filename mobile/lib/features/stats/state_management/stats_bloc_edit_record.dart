import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trailhead_mobile/features/stats/domain/stats_repository_personal_records.dart';
import '../domain/stats_use_case_record_time.dart';

typedef CreateRecordEditor = RecordEditorBloc Function();
typedef RecordEdit = ({
  Future<void> Function() operation,
  Completer<void> result,
});

class RecordEditorBloc extends Bloc<RecordEdit, bool> {
  RecordEditorBloc(this.engine) : super(false) {
    on<RecordEdit>((event, emit) async {
      emit(true);
      try {
        await event.operation();
        event.result.complete();
      } catch (error, trace) {
        event.result.completeError(error, trace);
      } finally {
        emit(false);
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  final PersonalRecordsRepository engine;

  Future<void> addBenchmark(String category, String minutes, String seconds) =>
      _submit(() async {
        final time = parseRecordTime(minutes, seconds);
        await engine.addManualRecord(category, time, DateTime.now(), null);
      });

  Future<void> removeBenchmark(String id) =>
      _submit(() => engine.deleteManualRecord(id));

  Future<void> _submit(Future<void> Function() operation) {
    if (isClosed || state)
      return Future.error(StateError('A record update is unavailable.'));
    final result = Completer<void>();
    add((operation: operation, result: result));
    return result.future;
  }
}

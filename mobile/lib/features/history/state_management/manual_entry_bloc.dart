import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/parsed_run_log.dart';
import '../domain/use_cases/parse_manual_run_log.dart';
import '../domain/use_cases/save_manual_run.dart';

sealed class ManualEntryEvent {
  const ManualEntryEvent();
}

final class ParseManualEntry extends ManualEntryEvent {
  const ParseManualEntry(this.text);

  final String text;
}

final class SaveManualEntry extends ManualEntryEvent {
  const SaveManualEntry({
    required this.distanceText,
    required this.effort,
    required this.conditions,
  });

  final String distanceText;
  final String effort;
  final String conditions;
}

class ManualEntryState {
  const ManualEntryState({
    this.isParsing = false,
    this.isSaving = false,
    this.parseCompleted = false,
    this.parsedLog,
    this.saveResult,
  });

  final bool isParsing;
  final bool isSaving;
  final bool parseCompleted;
  final ParsedRunLog? parsedLog;
  final ManualRunSaveResult? saveResult;
}

typedef CreateManualEntryBloc = ManualEntryBloc Function();

class ManualEntryBloc extends Bloc<ManualEntryEvent, ManualEntryState> {
  ManualEntryBloc(this._parseManualRunLog, this._saveManualRun)
    : super(const ManualEntryState()) {
    on<ParseManualEntry>(_parse);
    on<SaveManualEntry>(_save);
  }

  final ParseManualRunLog _parseManualRunLog;
  final SaveManualRun _saveManualRun;

  Future<void> _parse(
    ParseManualEntry event,
    Emitter<ManualEntryState> emit,
  ) async {
    if (state.isParsing || state.isSaving) return;
    emit(const ManualEntryState(isParsing: true));
    try {
      final parsedLog = await _parseManualRunLog(event.text);
      emit(ManualEntryState(parseCompleted: true, parsedLog: parsedLog));
    } catch (_) {
      emit(const ManualEntryState(parseCompleted: true));
    }
  }

  Future<void> _save(
    SaveManualEntry event,
    Emitter<ManualEntryState> emit,
  ) async {
    if (state.isParsing || state.isSaving) return;
    emit(const ManualEntryState(isSaving: true));
    try {
      final result = await _saveManualRun(
        distanceText: event.distanceText,
        effort: event.effort,
        conditions: event.conditions,
      );
      emit(ManualEntryState(saveResult: result));
    } catch (_) {
      emit(const ManualEntryState(saveResult: ManualRunSaveResult.failed));
    }
  }
}

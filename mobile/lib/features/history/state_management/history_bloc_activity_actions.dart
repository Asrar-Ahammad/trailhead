import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../run_tracking/data/models/run_isar.dart';
import 'history_bloc_route_points.dart';
import '../data/history_service_gpx_export.dart';

typedef CreateHistoryActionsBloc =
    HistoryActionsBloc Function(RunIsar run, HistoryRouteBloc route);

enum HistoryAction { exportGpx, delete }

typedef HistoryActionState = ({
  HistoryAction? busy,
  File? file,
  bool deleted,
  String? error,
});

class HistoryActionsBloc extends Bloc<HistoryAction, HistoryActionState> {
  HistoryActionsBloc(
    RunIsar run,
    HistoryRouteBloc route,
    RunGpxExportService exporter,
    Future<void> Function(int id, {String? clientRunId}) delete,
  ) : super((busy: null, file: null, deleted: false, error: null)) {
    on<HistoryAction>((action, emit) async {
      if (state.busy != null || state.deleted) return;
      emit((busy: action, file: null, deleted: false, error: null));
      try {
        if (action == HistoryAction.delete) {
          await delete(run.id, clientRunId: run.clientRunId);
          emit((busy: null, file: null, deleted: true, error: null));
        } else {
          final file = await exporter.export(run, await route.load());
          emit((busy: null, file: file, deleted: false, error: null));
        }
      } on FormatException catch (error) {
        emit((busy: null, file: null, deleted: false, error: error.message));
      } catch (_) {
        emit((
          busy: null,
          file: null,
          deleted: false,
          error: action == HistoryAction.delete
              ? 'Could not delete activity.'
              : 'Could not export GPX.',
        ));
      }
    });
  }
}

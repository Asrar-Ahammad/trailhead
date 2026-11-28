import 'package:flutter_bloc/flutter_bloc.dart';

typedef CreateRunPermissionsBloc = RunPermissionsBloc Function();

enum RunPermissionRequest { foreground, background }

typedef RunPermissionsState = ({RunPermissionRequest? pending, String? error});

class RunPermissionsBloc
    extends Bloc<RunPermissionRequest, RunPermissionsState> {
  RunPermissionsBloc({
    required Future<bool> Function() foreground,
    required Future<bool> Function() background,
    required Future<void> Function() promptBatterySettings,
  }) : super((pending: null, error: null)) {
    on<RunPermissionRequest>((request, emit) async {
      if (state.pending != null) return;
      emit((pending: request, error: null));
      final needsBackground = request == RunPermissionRequest.background;
      try {
        final granted = await (needsBackground ? background() : foreground());
        if (granted && needsBackground) await promptBatterySettings();
        emit((
          pending: null,
          error: granted
              ? null
              : needsBackground
              ? "Background location permission denied. Change permission to 'Allow all the time' in settings."
              : 'Foreground location permission denied. Please enable location permissions.',
        ));
      } catch (_) {
        emit((pending: null, error: 'Could not request location permission.'));
      }
    });
  }
}

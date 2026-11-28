import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../profile/domain/profile_repository_settings.dart';
import '../data/models/run_isar.dart';
import '../domain/run_tracking_use_case_validate_weight.dart';

typedef CreateWorkoutActionsBloc = WorkoutActionsBloc Function();
typedef CompletedWorkout = ({RunIsar run, List<LatLng> points});
typedef WorkoutActionState = ({
  bool saving,
  CompletedWorkout? workout,
  String? error,
});

enum WorkoutAction { finish }

class WorkoutActionsBloc extends Bloc<WorkoutAction, WorkoutActionState> {
  WorkoutActionsBloc(
    this.profile,
    Future<RunIsar?> Function() stop,
    Future<List<LatLng>> Function(String) readRoute,
    List<LatLng> Function() cachedRoute,
  ) : super((saving: false, workout: null, error: null)) {
    on<WorkoutAction>((event, emit) async {
      if (state.saving) return;
      emit((saving: true, workout: null, error: null));
      try {
        final fallback = cachedRoute();
        final run = await stop();
        if (run == null) {
          emit((saving: false, workout: null, error: null));
          return;
        }
        final id = run.clientRunId;
        var points = fallback;
        if (id != null) {
          try {
            points = await readRoute(id);
          } catch (_) {
            /* Keep the last live route. */
          }
        }
        emit((saving: false, workout: (run: run, points: points), error: null));
      } catch (_) {
        emit((saving: false, workout: null, error: 'Could not save workout.'));
      }
    });
  }

  final ProfileSettingsRepository profile;
  bool get needsWeight => profile.read().weight == null;

  Future<void> saveWeight(String input) =>
      profile.write(ProfileSetting.weight, parseTrackingWeight(input));
}

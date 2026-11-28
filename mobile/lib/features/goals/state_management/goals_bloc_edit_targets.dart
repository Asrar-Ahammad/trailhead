import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/goals_repository_targets.dart';

typedef CreateEditGoalsBloc = EditGoalsBloc Function();
typedef GoalTargetInput = ({
  String dailyMetric,
  String daily,
  String monthlyMetric,
  String monthly,
});

class EditGoalsBloc
    extends Bloc<GoalTargetInput, ({bool saving, bool saved, String? error})> {
  EditGoalsBloc(Future<void> Function(Goals) save)
    : super((saving: false, saved: false, error: null)) {
    on<GoalTargetInput>((input, emit) async {
      if (state.saving || state.saved) return;
      emit((saving: true, saved: false, error: null));
      try {
        await save(
          Goals.parseTargets(
            input.dailyMetric,
            input.daily,
            input.monthlyMetric,
            input.monthly,
          ),
        );
        emit((saving: false, saved: true, error: null));
      } on FormatException catch (error) {
        emit((saving: false, saved: false, error: error.message));
      } catch (_) {
        emit((
          saving: false,
          saved: false,
          error: 'Could not save goals. Please try again.',
        ));
      }
    });
  }
}

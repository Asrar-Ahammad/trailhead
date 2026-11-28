import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../domain/goals_use_case_calculate_progress.dart';

typedef CreateGoalProgressBloc = GoalProgressBloc Function(GoalMetrics metrics);

class GoalProgressBloc extends AsyncResourceBloc<GoalProgressData> {
  GoalProgressBloc(GoalProgressRepository repository, GoalMetrics metrics) {
    add(WatchResource(repository.watch(metrics)));
  }
}

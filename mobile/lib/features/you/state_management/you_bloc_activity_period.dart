import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../../run_tracking/data/models/daily_steps_isar.dart';
import '../../run_tracking/data/models/run_isar.dart';

typedef CreateDailyStepsBloc = DailyStepsBloc Function(DateTime date);
typedef CreatePeriodActivitiesBloc =
    PeriodActivitiesBloc Function(DateTime start, DateTime end);

class DailyStepsBloc extends AsyncResourceBloc<DailyStepsIsar?> {
  DailyStepsBloc(Stream<DailyStepsIsar?> steps) {
    add(WatchResource(steps));
  }
}

class PeriodActivitiesBloc extends AsyncResourceBloc<List<RunIsar>> {
  PeriodActivitiesBloc(Stream<List<RunIsar>> runs) {
    add(WatchResource(runs));
  }
}

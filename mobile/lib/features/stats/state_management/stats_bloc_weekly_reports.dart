import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../data/models/weekly_report_model.dart';

typedef CreateWeeklyReportsBloc = WeeklyReportsBloc Function();

class WeeklyReportsBloc extends AsyncResourceBloc<List<WeeklyReportModel>> {
  WeeklyReportsBloc(this.load) {
    add(LoadResource(load));
  }

  final Future<List<WeeklyReportModel>> Function() load;

  Future<void> refresh() async {
    final settled = stream.firstWhere((state) => !state.isLoading);
    if (!state.isLoading) add(LoadResource(load));
    await settled;
  }
}

import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../data/shoes_repository_implementation_activity.dart';
import '../domain/shoes_use_case_activity_summary.dart';

typedef CreateShoeActivityBloc =
    ShoeActivityBloc Function(String? clientShoeId);
typedef ShoeActivityData = ({List<RunIsar> runs, ShoeActivitySummary summary});

class ShoeActivityBloc extends AsyncResourceBloc<ShoeActivityData> {
  ShoeActivityBloc(ShoeActivityRepository repository, String? clientShoeId) {
    add(
      WatchResource(
        repository
            .watchRuns(clientShoeId)
            .map(
              (runs) => (
                runs: runs,
                summary: summarizeShoeActivity(
                  runs.map(
                    (run) => (
                      distanceMeters: run.distanceM ?? 0,
                      durationSeconds: run.durationS ?? 0,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../data/models/run_isar.dart';

typedef CreatePostRunSummaryBloc = PostRunSummaryBloc Function(RunIsar run);
typedef PostRunSummaryData = ({String aiSummary, bool isNewPr});

class PostRunSummaryBloc extends AsyncResourceBloc<PostRunSummaryData> {
  PostRunSummaryBloc(
    RunIsar run, {
    required Future<String> Function(RunIsar) summarize,
    required Future<bool> Function(String) hasRecord,
  }) {
    add(
      LoadResource(() async {
        final id = run.clientRunId;
        final (summary, record) = await (
          summarize(run),
          id == null ? Future.value(false) : hasRecord(id),
        ).wait;
        return (aiSummary: summary, isNewPr: record);
      }),
    );
  }
}

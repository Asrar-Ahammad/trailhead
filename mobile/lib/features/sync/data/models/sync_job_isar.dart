import 'package:isar/isar.dart';

part 'sync_job_isar.g.dart';

@collection
class SyncJobIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String clientRunId;

  /// 'pending', 'in_progress', 'failed', 'completed'
  late String status;

  int attempts = 0;

  DateTime? nextRetryAt;
}

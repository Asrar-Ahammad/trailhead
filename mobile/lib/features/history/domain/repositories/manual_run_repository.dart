import '../entities/manual_run.dart';

abstract interface class ManualRunRepository {
  Future<void> saveManualRun(ManualRun run);
}

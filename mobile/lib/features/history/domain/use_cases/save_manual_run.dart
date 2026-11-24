import '../entities/manual_run.dart';
import '../repositories/manual_run_repository.dart';

enum ManualRunSaveResult { saved, invalidDistance, failed }

class SaveManualRun {
  const SaveManualRun(this._repository);

  final ManualRunRepository _repository;

  Future<ManualRunSaveResult> call({
    required String distanceText,
    required String effort,
    required String conditions,
  }) async {
    final distanceKm = double.tryParse(distanceText);
    if (distanceKm == null || distanceKm <= 0) {
      return ManualRunSaveResult.invalidDistance;
    }

    final endTime = DateTime.now();
    final run = ManualRun(
      clientRunId: endTime.millisecondsSinceEpoch.toString(),
      startTime: endTime.subtract(const Duration(hours: 1)),
      endTime: endTime,
      distanceKm: distanceKm,
      subjectiveEffort: effort.isEmpty ? null : effort,
      conditions: conditions.isEmpty ? null : conditions,
    );
    await _repository.saveManualRun(run);
    return ManualRunSaveResult.saved;
  }
}

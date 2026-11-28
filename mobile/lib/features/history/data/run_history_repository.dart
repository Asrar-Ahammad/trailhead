import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/features/stats/data/models/personal_record_isar.dart';
import '../domain/entities/manual_run.dart';
import '../domain/repositories/manual_run_repository.dart';

class RunHistoryRepository implements ManualRunRepository {
  final Isar _isar;

  RunHistoryRepository(this._isar);

  Future<List<RunIsar>> getCompletedRuns({int limit = 50, int offset = 0}) async {
    return _isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .sortByStartTimeDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Stream<List<RunIsar>> watchCompletedRuns({int limit = 50, int offset = 0}) {
    return _isar.runIsars
        .filter()
        .statusEqualTo('completed')
        .sortByStartTimeDesc()
        .offset(offset)
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Stream<List<RunIsar>> watchPeriod(DateTime start, DateTime end) => _isar.runIsars
      .filter().statusEqualTo('completed')
      .startTimeGreaterThan(start, include: true).startTimeLessThan(end)
      .sortByStartTimeDesc().watch(fireImmediately: true);

  Future<RunIsar?> getRunById(int id) async {
    return _isar.runIsars.get(id);
  }

  Future<RunIsar?> getRunByClientRunId(String clientRunId) async {
    return _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
  }

  Future<List<RunPointIsar>> getRunPoints(String clientRunId) async {
    return _isar.runPointIsars
        .filter()
        .clientRunIdEqualTo(clientRunId)
        .sortBySequence()
        .findAll();
  }

  Future<void> deleteRun(int id, {String? clientRunId}) =>
      _isar.writeTxn(() => _deleteRun(id, clientRunId));

  Future<void> deleteRuns(Set<int> ids) => _isar.writeTxn(() async {
    for (final id in ids) {
      await _deleteRun(id, null);
    }
  });

  Future<void> _deleteRun(int id, String? clientRunId) async {
    var run = await _isar.runIsars.get(id);
    if (run == null && clientRunId != null && clientRunId.isNotEmpty) {
      run = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
    }
    final trackingId = run?.clientRunId ?? clientRunId;
    if (run != null) await _isar.runIsars.delete(run.id);
    if (trackingId == null || trackingId.isEmpty) return;
    await _isar.runPointIsars.filter().clientRunIdEqualTo(trackingId).deleteAll();
    await _isar.personalRecordIsars.filter().runIdEqualTo(trackingId).deleteAll();
  }

  Future<void> saveRun(RunIsar run, [List<RunPointIsar> points = const []]) async {
    await _isar.writeTxn(() async {
      await _isar.runIsars.put(run);
      if (points.isNotEmpty) {
        await _isar.runPointIsars.putAll(points);
      }
    });
  }

  @override
  Future<void> saveManualRun(ManualRun manualRun) {
    final now = manualRun.endTime;
    final distanceMeters = manualRun.distanceKm * 1000;
    final run = RunIsar()
      ..clientRunId = manualRun.clientRunId
      ..startTime = manualRun.startTime
      ..endTime = manualRun.endTime
      ..distanceM = distanceMeters
      ..durationS = 3600
      ..avgPaceSPerKm = 3600 / manualRun.distanceKm
      ..title = 'Manual Run'
      ..synced = false
      ..status = 'completed'
      ..subjectiveEffort = manualRun.subjectiveEffort
      ..conditions = manualRun.conditions
      ..lastModifiedAt = now;
    return saveRun(run);
  }
}

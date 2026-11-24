import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/features/stats/data/models/personal_record_isar.dart';
import 'package:trailhead_mobile/main.dart'; // To access isarInstance
import '../domain/entities/manual_run.dart';
import '../domain/repositories/manual_run_repository.dart';

final runHistoryRepositoryProvider = Provider((ref) => RunHistoryRepository(isarInstance));

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

  Future<void> deleteRun(int id, {String? clientRunId}) async {
    RunIsar? run = await _isar.runIsars.get(id);
    if (run == null && clientRunId != null && clientRunId.isNotEmpty) {
      run = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
    }
    if (run == null && (clientRunId == null || clientRunId.isEmpty)) return;

    final resolvedClientRunId = run?.clientRunId ?? clientRunId;
    final resolvedId = run?.id ?? id;

    List<int> pointIds = [];
    List<int> prIds = [];
    if (resolvedClientRunId != null && resolvedClientRunId.isNotEmpty) {
      final points = await _isar.runPointIsars
          .filter()
          .clientRunIdEqualTo(resolvedClientRunId)
          .findAll();
      pointIds = points.map((p) => p.id).toList();

      final prs = await _isar.personalRecordIsars
          .filter()
          .runIdEqualTo(resolvedClientRunId)
          .findAll();
      prIds = prs.map((p) => p.id).toList();
    }

    await _isar.writeTxn(() async {
      await _isar.runIsars.delete(resolvedId);
      if (pointIds.isNotEmpty) {
        await _isar.runPointIsars.deleteAll(pointIds);
      }
      if (prIds.isNotEmpty) {
        await _isar.personalRecordIsars.deleteAll(prIds);
      }
    });
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

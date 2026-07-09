import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/main.dart'; // To access isarInstance

final runHistoryRepositoryProvider = Provider((ref) => RunHistoryRepository(isarInstance));

class RunHistoryRepository {
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

  Future<void> deleteRun(int id) async {
    await _isar.writeTxn(() async {
      await _isar.runIsars.delete(id);
    });
  }
}

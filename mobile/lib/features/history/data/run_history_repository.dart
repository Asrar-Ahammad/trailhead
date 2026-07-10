import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_isar.dart';
import 'package:trailhead_mobile/features/run_tracking/data/models/run_point_isar.dart';
import 'package:trailhead_mobile/main.dart'; // To access isarInstance
import 'package:trailhead_mobile/features/sync/data/api_client.dart';
import 'package:flutter/foundation.dart';

final runHistoryRepositoryProvider = Provider((ref) => RunHistoryRepository(isarInstance, ref.read(apiClientProvider)));

class RunHistoryRepository {
  final Isar _isar;
  final ApiClient _apiClient;

  RunHistoryRepository(this._isar, this._apiClient);

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

  Future<void> deleteRun(int id) async {
    final run = await _isar.runIsars.get(id);
    if (run != null && run.clientRunId != null) {
      try {
        await _apiClient.client.delete('/runs/${run.clientRunId}');
      } catch (e) {
        debugPrint('Failed to delete on server: $e');
      }
    }

    await _isar.writeTxn(() async {
      await _isar.runIsars.delete(id);
    });
  }
}

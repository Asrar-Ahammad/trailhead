import 'package:isar/isar.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';
import '../data/models/sync_job_isar.dart';
import '../data/api_client.dart';
import 'package:workmanager/workmanager.dart';

class SyncService {
  final Isar isar;
  final ApiClient apiClient;

  SyncService({required this.isar, required this.apiClient});

  /// The entry point for the background sync task.
  Future<bool> runSyncLoop() async {
    final now = DateTime.now();
    
    // Find jobs that are pending or failed (and due for retry)
    final jobs = await isar.syncJobIsars.filter()
      .statusEqualTo('pending')
      .or()
      .group((q) => q.statusEqualTo('failed').and().nextRetryAtLessThan(now))
      .findAll();

    if (jobs.isEmpty) return true;

    bool allSuccess = true;

    for (final job in jobs) {
      bool success = await _syncSingleJob(job);
      if (!success) {
        allSuccess = false;
        
        // Exponential backoff
        job.status = 'failed';
        job.attempts += 1;
        final backoffMinutes = 5 * (1 << (job.attempts - 1)); // 5, 10, 20, 40...
        job.nextRetryAt = DateTime.now().add(Duration(minutes: backoffMinutes));
        
        await isar.writeTxn(() async {
          await isar.syncJobIsars.put(job);
        });
        
        // Schedule workmanager retry
        Workmanager().registerOneOffTask(
          "retry_sync_${job.clientRunId}",
          "sync_task",
          initialDelay: Duration(minutes: backoffMinutes),
          constraints: Constraints(networkType: NetworkType.connected),
        );
      }
    }

    return allSuccess;
  }

  Future<bool> _syncSingleJob(SyncJobIsar job) async {
    try {
      job.status = 'in_progress';
      await isar.writeTxn(() async {
        await isar.syncJobIsars.put(job);
      });

      final run = await isar.runIsars.filter().clientRunIdEqualTo(job.clientRunId).findFirst();
      if (run == null) {
        // Run deleted locally, drop job
        await isar.writeTxn(() async {
          await isar.syncJobIsars.delete(job.id);
        });
        return true;
      }

      // POST metadata
      final metadataResponse = await apiClient.client.post('/runs', data: {
        'clientRunId': run.clientRunId,
        'startTime': run.startTime?.toIso8601String(),
        'endTime': run.endTime?.toIso8601String(),
        'distanceM': run.distanceM ?? 0,
        'durationS': run.durationS ?? 0,
        'avgPaceSPerKm': run.avgPaceSPerKm ?? 0,
        'title': run.title,
      });

      if (metadataResponse.statusCode != 200 && metadataResponse.statusCode != 409) {
        return false;
      }

      // POST points in batches
      final points = await isar.runPointIsars.filter().clientRunIdEqualTo(job.clientRunId).sortBySequence().findAll();
      
      const batchSize = 500;
      for (int i = 0; i < points.length; i += batchSize) {
        final batch = points.skip(i).take(batchSize).toList();
        final pointsPayload = batch.map((p) => {
          'lat': p.lat,
          'lng': p.lng,
          'timestamp': p.timestamp?.toIso8601String(),
          'sequence': p.sequence,
        }).toList();

        final ptsResponse = await apiClient.client.post(
          '/runs/${run.clientRunId}/points',
          data: pointsPayload,
        );

        if (ptsResponse.statusCode != 200) {
          return false;
        }
      }

      // Success!
      job.status = 'completed';
      run.syncedAt = DateTime.now();
      
      await isar.writeTxn(() async {
        await isar.syncJobIsars.put(job);
        await isar.runIsars.put(run);
      });

      return true;
    } catch (e) {
      print('Sync error for job ${job.clientRunId}: $e');
      return false;
    }
  }
}

import 'package:isar/isar.dart';
import '../../run_tracking/data/models/run_isar.dart';
import '../../run_tracking/data/models/run_point_isar.dart';
import '../../shoes/data/models/shoe_isar.dart';
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
        'avgCadenceSpm': run.avgCadenceSpm,
        'avgStrideLengthM': run.avgStrideLengthM,
        'caloriesKcal': run.caloriesKcal,
        'stepCount': run.stepCount,
        'title': run.title,
        'activityType': run.activityType,
        'shoeId': run.clientShoeId,
        'weatherTemp': run.weatherTemp,
        'weatherCode': run.weatherCode,
      });

      if (metadataResponse.statusCode != 200 && metadataResponse.statusCode != 409) {
        return false;
      }

      // POST points in batches
      final points = await isar.runPointIsars.filter().clientRunIdEqualTo(job.clientRunId).sortBySequence().findAll();
      
      if (points.isEmpty) {
        final tz = DateTime.now().timeZoneName;
        final ptsResponse = await apiClient.client.post(
          '/runs/${run.clientRunId}/points',
          queryParameters: {'done': 'true', 'tz': tz},
          data: [],
        );
        if (ptsResponse.statusCode != 200) {
          return false;
        }
      } else {
        const batchSize = 500;
        for (int i = 0; i < points.length; i += batchSize) {
          final batch = points.skip(i).take(batchSize).toList();
          final pointsPayload = batch.map((p) => {
            'lat': p.lat,
            'lng': p.lng,
            'elevation': p.elevation,
            'timestamp': p.timestamp?.toIso8601String(),
            'accuracy': p.accuracy,
            'cadence': p.cadence,
            'sequence': p.sequence,
          }).toList();

          final isFinalBatch = (i + batchSize) >= points.length;
          final tz = DateTime.now().timeZoneName;
          final queryParams = <String, dynamic>{};
          if (isFinalBatch) {
            queryParams['done'] = 'true';
            queryParams['tz'] = tz;
          }

          final ptsResponse = await apiClient.client.post(
            '/runs/${run.clientRunId}/points',
            queryParameters: queryParams,
            data: pointsPayload,
          );

          if (ptsResponse.statusCode != 200) {
            return false;
          }
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

  /// Fetch existing runs from the server (used on first login)
  Future<void> fetchInitialData() async {
    try {
      int page = 1;
      int totalPages = 1;
      do {
        final response = await apiClient.client.get('/runs?page=$page&limit=20');
        if (response.statusCode == 200) {
          final data = response.data;
          final runsList = data['runs'] as List<dynamic>;
          totalPages = data['pagination']['totalPages'] as int;

          for (final runJson in runsList) {
            final clientRunId = runJson['id'];
            
            // Check if it exists locally
            final existingRun = await isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
            if (existingRun == null) {
              // Fetch detailed run to get points
              final detailResponse = await apiClient.client.get('/runs/$clientRunId');
              if (detailResponse.statusCode == 200) {
                final detailData = detailResponse.data;
                
                final run = RunIsar()
                  ..clientRunId = detailData['id']
                  ..title = detailData['title']
                  ..startTime = DateTime.parse(detailData['startTime']).toLocal()
                  ..endTime = DateTime.parse(detailData['endTime']).toLocal()
                  ..distanceM = (detailData['distanceM'] as num?)?.toDouble()
                  ..durationS = detailData['durationS'] as int?
                  ..avgPaceSPerKm = (detailData['avgPaceSPerKm'] as num?)?.toDouble()
                  ..avgCadenceSpm = (detailData['avgCadenceSpm'] as num?)?.toDouble()
                  ..avgStrideLengthM = (detailData['avgStrideLengthM'] as num?)?.toDouble()
                  ..caloriesKcal = (detailData['caloriesKcal'] as num?)?.toDouble()
                  ..stepCount = detailData['stepCount'] as int?
                  ..elevationGainM = (detailData['elevationGainM'] as num?)?.toDouble()
                  ..activityType = detailData['activityType']
                  ..weatherTemp = (detailData['weatherTemp'] as num?)?.toDouble()
                  ..weatherCode = (detailData['weatherCode'] as num?)?.toDouble()
                  ..status = 'completed'
                  ..synced = true
                  ..syncedAt = DateTime.now();

                final pointsData = detailData['points'] as List<dynamic>? ?? [];
                final points = pointsData.map((p) => RunPointIsar()
                  ..clientRunId = clientRunId
                  ..lat = (p['lat'] as num).toDouble()
                  ..lng = (p['lng'] as num).toDouble()
                  ..elevation = (p['elevation'] as num?)?.toDouble()
                  ..timestamp = DateTime.parse(p['timestamp']).toLocal()
                  ..cadence = p['cadence'] as int?
                  ..sequence = p['sequence'] as int
                ).toList();

                await isar.writeTxn(() async {
                  await isar.runIsars.put(run);
                  await isar.runPointIsars.putAll(points);
                });
              }
            }
          }
        }
        page++;
      } while (page <= totalPages);
    } catch (e) {
      print('initialSync error: $e');
    }
  }

  Future<void> syncShoe(ShoeIsar shoe) async {
    try {
      final shoeModelResponse = await apiClient.client.post('/shoes', data: {
        'id': shoe.clientShoeId,
        'name': shoe.name,
        'brand': shoe.brand,
        'distanceM': shoe.distanceM,
        'isActive': shoe.isActive,
        'createdAt': shoe.createdAt?.toIso8601String(),
      });
      if (shoeModelResponse.statusCode != 200 && shoeModelResponse.statusCode != 201) {
        throw Exception('Failed to sync shoe');
      }
    } catch (e) {
      throw Exception('Failed to sync shoe: $e');
    }
  }

  Future<void> deleteShoe(String clientShoeId) async {
    try {
      final response = await apiClient.client.delete('/shoes/$clientShoeId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete shoe from backend');
      }
    } catch (e) {
      throw Exception('Failed to delete shoe: $e');
    }
  }
}

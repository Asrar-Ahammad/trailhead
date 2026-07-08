import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';
import 'location_service_task.dart';
import '../../../main.dart'; // import global isarInstance
import '../data/models/run_isar.dart';
import '../data/models/run_point_isar.dart';
import '../../sync/data/models/sync_job_isar.dart';

class RunTrackerState {
  final String status; // 'idle', 'running', 'paused', 'stopped'
  final String? clientRunId;
  final double distanceM;
  final int durationS;
  final int stepCount;
  final bool gpsWeak;
  final bool permissionsGranted;

  RunTrackerState({
    required this.status,
    this.clientRunId,
    this.distanceM = 0.0,
    this.durationS = 0,
    this.stepCount = 0,
    this.gpsWeak = false,
    this.permissionsGranted = false,
  });

  RunTrackerState copyWith({
    String? status,
    String? clientRunId,
    double? distanceM,
    int? durationS,
    int? stepCount,
    bool? gpsWeak,
    bool? permissionsGranted,
  }) {
    return RunTrackerState(
      status: status ?? this.status,
      clientRunId: clientRunId ?? this.clientRunId,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      stepCount: stepCount ?? this.stepCount,
      gpsWeak: gpsWeak ?? this.gpsWeak,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    );
  }
}

class RunTrackerController extends StateNotifier<RunTrackerState> {
  StreamSubscription? _portSubscription;

  RunTrackerController() : super(RunTrackerState(status: 'idle')) {
    _initForegroundTask();
    _checkPermissionsSilently();
    _recoverOrphanedRuns();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'trailhead_tracking',
        channelName: 'Run Tracking',
        channelDescription: 'Shows live stats during run tracking.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );

    // Listen to background isolate messages
    FlutterForegroundTask.receivePort?.listen((message) {
      if (message is Map<String, dynamic>) {
        final type = message['type'];
        if (type == 'stats_update') {
          state = state.copyWith(
            distanceM: message['distanceM'] as double,
            durationS: message['durationS'] as int,
            stepCount: message['stepCount'] as int,
            status: (message['isPaused'] as bool) ? 'paused' : 'running',
          );
        } else if (type == 'gps_weak') {
          state = state.copyWith(gpsWeak: message['weak'] as bool);
        }
      }
    });
  }

  Future<void> _checkPermissionsSilently() async {
    final hasLocation = await Geolocator.checkPermission();
    final isGranted = hasLocation == LocationPermission.always ||
        hasLocation == LocationPermission.whileInUse;
    
    // Also check background if Android 10+
    bool backgroundGranted = true;
    if (isGranted) {
      // In a real app we might verify if it is specifically 'always' for background location.
      // But for simplicity of check, we align with isGranted.
      backgroundGranted = hasLocation == LocationPermission.always;
    }

    state = state.copyWith(permissionsGranted: isGranted && backgroundGranted);
  }

  Future<bool> requestForegroundPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    
    state = state.copyWith(permissionsGranted: granted);
    return granted;
  }

  Future<bool> requestBackgroundPermission() async {
    // Note: Android 10+ requires checking/requesting 'always' permission for background location.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse) {
      // Request always permission
      permission = await Geolocator.requestPermission();
    }
    
    final granted = permission == LocationPermission.always;
    state = state.copyWith(permissionsGranted: granted);
    return granted;
  }

  Future<void> _recoverOrphanedRuns() async {
    // Check if service is currently running
    final isServiceRunning = await FlutterForegroundTask.isRunningService;
    if (isServiceRunning) {
      // Re-attach UI to running run
      final activeRun = await isarInstance.runIsars.filter().statusEqualTo('running').findFirst();
      if (activeRun != null) {
        state = state.copyWith(
          status: 'running',
          clientRunId: activeRun.clientRunId,
          distanceM: activeRun.distanceM ?? 0.0,
          durationS: activeRun.durationS ?? 0,
          stepCount: activeRun.stepCount ?? 0,
        );
      }
      return;
    }

    // Find runs marked 'running' or 'paused' in database which are orphaned
    final orphanedRuns = await isarInstance.runIsars
        .filter()
        .statusEqualTo('running')
        .or()
        .statusEqualTo('paused')
        .findAll();

    if (orphanedRuns.isNotEmpty) {
      await isarInstance.writeTxn(() async {
        for (final run in orphanedRuns) {
          run.status = 'completed';
          run.endTime = DateTime.now();
          run.lastModifiedAt = DateTime.now();
          await isarInstance.runIsars.put(run);
        }
      });
    }
  }

  Future<void> startRun() async {
    if (state.status != 'idle') return;

    final String clientRunId = const Uuid().v4();
    final DateTime now = DateTime.now();

    final newRun = RunIsar()
      ..clientRunId = clientRunId
      ..startTime = now
      ..status = 'running'
      ..distanceM = 0.0;

    await isarInstance.writeTxn(() async {
      await isarInstance.runIsars.put(newRun);
    });

    state = RunTrackerState(
      status: 'running',
      clientRunId: clientRunId,
      distanceM: 0.0,
      durationS: 0,
      stepCount: 0,
      permissionsGranted: state.permissionsGranted,
    );

    // Start Foreground Service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Trailhead',
      notificationText: 'Tracking your run...',
      callback: startCallback,
    );
  }

  Future<void> pauseRun() async {
    if (state.status != 'running') return;

    FlutterForegroundTask.sendDataToTask({'action': 'pause'});
    
    final activeRun = await isarInstance.runIsars.filter().clientRunIdEqualTo(state.clientRunId).findFirst();
    if (activeRun != null) {
      activeRun.status = 'paused';
      await isarInstance.writeTxn(() async {
        await isarInstance.runIsars.put(activeRun);
      });
    }

    state = state.copyWith(status: 'paused');
  }

  Future<void> resumeRun() async {
    if (state.status != 'paused') return;

    FlutterForegroundTask.sendDataToTask({'action': 'resume'});

    final activeRun = await isarInstance.runIsars.filter().clientRunIdEqualTo(state.clientRunId).findFirst();
    if (activeRun != null) {
      activeRun.status = 'running';
      await isarInstance.writeTxn(() async {
        await isarInstance.runIsars.put(activeRun);
      });
    }

    state = state.copyWith(status: 'running');
  }

  Future<RunIsar?> stopRun() async {
    if (state.status != 'running' && state.status != 'paused') return null;

    await FlutterForegroundTask.stopService();

    final activeRun = await isarInstance.runIsars.filter().clientRunIdEqualTo(state.clientRunId).findFirst();
    if (activeRun != null) {
      activeRun.status = 'completed';
      activeRun.endTime = DateTime.now();
      activeRun.lastModifiedAt = DateTime.now();
      
      // Compute final avg pace
      if (activeRun.distanceM != null && activeRun.distanceM! > 0) {
        activeRun.avgPaceSPerKm = (activeRun.durationS ?? 0) / (activeRun.distanceM! / 1000.0);
      }
      
      await isarInstance.writeTxn(() async {
        await isarInstance.runIsars.put(activeRun);
        
        if (activeRun.clientRunId != null) {
          final syncJob = SyncJobIsar()
            ..clientRunId = activeRun.clientRunId!
            ..status = 'pending'
            ..attempts = 0;
          await isarInstance.syncJobIsars.put(syncJob);
        }
      });

      // Schedule immediate sync attempt
      if (activeRun.clientRunId != null) {
        Workmanager().registerOneOffTask(
          "sync_${activeRun.clientRunId}",
          "sync_task",
          constraints: Constraints(networkType: NetworkType.connected),
        );
      }
    }

    state = state.copyWith(status: 'stopped');
    return activeRun;
  }

  Future<void> discardRun() async {
    if (state.clientRunId == null) return;

    await FlutterForegroundTask.stopService();

    final clientRunId = state.clientRunId!;
    await isarInstance.writeTxn(() async {
      final run = await isarInstance.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
      if (run != null) {
        await isarInstance.runIsars.delete(run.id);
      }
      // Delete points
      final points = await isarInstance.runPointIsars.filter().clientRunIdEqualTo(clientRunId).findAll();
      for (final p in points) {
        await isarInstance.runPointIsars.delete(p.id);
      }
    });

    state = RunTrackerState(
      status: 'idle',
      permissionsGranted: state.permissionsGranted,
    );
  }

  @override
  void dispose() {
    _portSubscription?.cancel();
    super.dispose();
  }
}

final runTrackerProvider = StateNotifierProvider<RunTrackerController, RunTrackerState>((ref) {
  return RunTrackerController();
});

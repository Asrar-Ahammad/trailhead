import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';
import 'location_service_task.dart';
import '../../../main.dart'; // import global isarInstance
import '../data/models/run_isar.dart';
import '../data/models/run_point_isar.dart';
import '../../sync/data/models/sync_job_isar.dart';
import '../../sync/data/api_client.dart';
import '../../notifications/application/notification_service.dart';

import '../../shoes/application/shoe_service.dart';

class RunTrackerState {
  final String status; // 'idle', 'running', 'paused', 'stopped'
  final String? clientRunId;
  final double distanceM;
  final int durationS;
  final int stepCount;
  final bool gpsWeak;
  final bool permissionsGranted;
  final bool permissionsChecked;
  final int? targetPaceSPerKm;
  final int? currentSplitPaceSPerKm;
  final Position? initialPosition;
  final String activityType; // "run" or "walk"
  final String? selectedShoeId;

  RunTrackerState({
    required this.status,
    this.clientRunId,
    this.distanceM = 0.0,
    this.durationS = 0,
    this.stepCount = 0,
    this.gpsWeak = false,
    this.permissionsGranted = false,
    this.permissionsChecked = false,
    this.targetPaceSPerKm,
    this.currentSplitPaceSPerKm,
    this.initialPosition,
    this.activityType = 'run',
    this.selectedShoeId,
  });

  RunTrackerState copyWith({
    String? status,
    String? clientRunId,
    double? distanceM,
    int? durationS,
    int? stepCount,
    bool? gpsWeak,
    bool? permissionsGranted,
    bool? permissionsChecked,
    int? targetPaceSPerKm,
    int? currentSplitPaceSPerKm,
    Position? initialPosition,
    String? activityType,
    String? selectedShoeId,
  }) {
    return RunTrackerState(
      status: status ?? this.status,
      clientRunId: clientRunId ?? this.clientRunId,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      stepCount: stepCount ?? this.stepCount,
      gpsWeak: gpsWeak ?? this.gpsWeak,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      permissionsChecked: permissionsChecked ?? this.permissionsChecked,
      targetPaceSPerKm: targetPaceSPerKm ?? this.targetPaceSPerKm,
      currentSplitPaceSPerKm: currentSplitPaceSPerKm ?? this.currentSplitPaceSPerKm,
      initialPosition: initialPosition ?? this.initialPosition,
      activityType: activityType ?? this.activityType,
      selectedShoeId: selectedShoeId ?? this.selectedShoeId,
    );
  }
}

class RunTrackerController extends StateNotifier<RunTrackerState> {
  StreamSubscription? _portSubscription;
  final FlutterTts _flutterTts = FlutterTts();
  final Ref ref;

  RunTrackerController(this.ref) : super(RunTrackerState(status: 'idle')) {
    _initForegroundTask();
    _checkPermissionsSilently();
    _recoverOrphanedRuns();
    _initTts();
    _initDefaultShoe();
  }

  Future<void> _initDefaultShoe() async {
    try {
      final shoeService = ref.read(shoeServiceProvider);
      final activeShoes = await shoeService.getActiveShoes();
      if (activeShoes.isNotEmpty) {
        state = state.copyWith(selectedShoeId: activeShoes.first.clientShoeId);
      }
    } catch (e) {
      debugPrint('[RUN_TRACKER] Failed to init default shoe: $e');
    }
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'trailhead_tracking',
        channelName: 'Run Tracking',
        channelDescription: 'Shows live stats during run tracking.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
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
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map) {
        final type = data['type'];
        if (type == 'stats_update') {
          state = state.copyWith(
            distanceM: (data['distanceM'] as num).toDouble(),
            durationS: (data['durationS'] as num).toInt(),
            stepCount: (data['stepCount'] as num).toInt(),
            status: (data['isPaused'] as bool) ? 'paused' : 'running',
            currentSplitPaceSPerKm: data['currentSplitPaceSPerKm'] != null ? (data['currentSplitPaceSPerKm'] as num).toInt() : null,
          );
        } else if (type == 'gps_weak') {
          state = state.copyWith(gpsWeak: data['weak'] as bool);
        } else if (type == 'split_reached') {
          final double splitDist = data['splitDistance'] != null 
              ? (data['splitDistance'] as num).toDouble() 
              : (data['km'] as num).toDouble();
          _handleSplitReached(splitDist, (data['timeS'] as num).toInt(), (data['paceSPerKm'] as num).toInt());
        }
      }
    });
  }

  void _handleSplitReached(double distance, int splitTimeS, int paceSPerKm) async {
    HapticFeedback.heavyImpact();
    
    final prefs = await SharedPreferences.getInstance();
    final audioCuesEnabled = prefs.getBool('audio_cues_enabled') ?? true;
    
    if (audioCuesEnabled) {
      final int paceMin = (paceSPerKm / 60).floor();
      final int paceSec = (paceSPerKm % 60).round();
      
      final String distStr = distance % 1 == 0 ? distance.toInt().toString() : distance.toStringAsFixed(1);
      final String text = "Kilometer $distStr. Split pace $paceMin minutes $paceSec seconds.";
      await _flutterTts.speak(text);
    }
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

    Position? pos;
    if (isGranted) {
      try {
        pos = await Geolocator.getLastKnownPosition();
        if (pos == null) {
          Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).then((p) {
            state = state.copyWith(initialPosition: p);
          }).catchError((_) {});
        }
      } catch (_) {}
    }

    state = state.copyWith(
      permissionsGranted: isGranted && backgroundGranted, 
      permissionsChecked: true,
      initialPosition: pos
    );
  }

  Future<bool> requestForegroundPermission() async {
    // Request notification and physical activity permissions sequentially
    await Permission.notification.request();
    await Permission.activityRecognition.request();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    
    Position? pos = state.initialPosition;
    if (granted && pos == null) {
      try {
        pos = await Geolocator.getLastKnownPosition();
        if (pos == null) {
          Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).then((p) {
            state = state.copyWith(initialPosition: p);
          }).catchError((_) {});
        }
      } catch (_) {}
    }
    
    state = state.copyWith(permissionsGranted: granted, initialPosition: pos);
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
    
    Position? pos = state.initialPosition;
    if (granted && pos == null) {
      try {
        pos = await Geolocator.getLastKnownPosition();
        if (pos == null) {
          Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).then((p) {
            state = state.copyWith(initialPosition: p);
          }).catchError((_) {});
        }
      } catch (_) {}
    }
    
    state = state.copyWith(permissionsGranted: granted, initialPosition: pos);
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

  void setTargetPace(int? paceS) {
    state = RunTrackerState(
      status: state.status,
      clientRunId: state.clientRunId,
      distanceM: state.distanceM,
      durationS: state.durationS,
      stepCount: state.stepCount,
      gpsWeak: state.gpsWeak,
      permissionsGranted: state.permissionsGranted,
      permissionsChecked: state.permissionsChecked,
      targetPaceSPerKm: paceS,
      currentSplitPaceSPerKm: state.currentSplitPaceSPerKm,
      initialPosition: state.initialPosition,
      activityType: state.activityType,
    );
  }
  
  void updateInitialPosition(Position pos) {
    state = state.copyWith(initialPosition: pos);
  }

  void setActivityType(String type) {
    state = state.copyWith(activityType: type);
  }

  void setSelectedShoe(String? shoeId) {
    state = state.copyWith(selectedShoeId: shoeId);
  }

  Future<void> startRun() async {
    if (state.status != 'idle') return;

    final String clientRunId = const Uuid().v4();
    final DateTime now = DateTime.now();

    final newRun = RunIsar()
      ..clientRunId = clientRunId
      ..startTime = now
      ..status = 'running'
      ..activityType = state.activityType
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
      initialPosition: state.initialPosition,
      targetPaceSPerKm: state.targetPaceSPerKm,
      activityType: state.activityType,
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
    debugPrint('[STOP_RUN] Called. state.status=${state.status}, clientRunId=${state.clientRunId}');
    if (state.status != 'running' && state.status != 'paused') {
      debugPrint('[STOP_RUN] EARLY RETURN - status is ${state.status}, not running or paused');
      return null;
    }

    try {
      await FlutterForegroundTask.stopService();
      debugPrint('[STOP_RUN] Foreground service stopped');
    } catch (e) {
      debugPrint('[STOP_RUN] Error stopping foreground service: $e');
    }

    final activeRun = await isarInstance.runIsars.filter().clientRunIdEqualTo(state.clientRunId).findFirst();
    debugPrint('[STOP_RUN] Found activeRun in Isar: ${activeRun != null}, id=${activeRun?.clientRunId}');
    
    if (activeRun != null) {
      activeRun.status = 'completed';
      activeRun.endTime = DateTime.now();
      activeRun.lastModifiedAt = DateTime.now();
      
      // Compute final avg pace
      if (activeRun.distanceM != null && activeRun.distanceM! > 0) {
        activeRun.avgPaceSPerKm = (activeRun.durationS ?? 0) / (activeRun.distanceM! / 1000.0);
      }
      
      activeRun.clientShoeId = state.selectedShoeId;
      
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
      debugPrint('[STOP_RUN] Isar write completed successfully');
      
      if (state.selectedShoeId != null && activeRun.distanceM != null && activeRun.distanceM! > 0) {
        try {
          final shoeService = ref.read(shoeServiceProvider);
          await shoeService.addDistanceToShoe(state.selectedShoeId!, activeRun.distanceM!);
        } catch (e) {
          debugPrint('[STOP_RUN] Failed to add distance to shoe: $e');
        }
      }

      // Schedule immediate sync attempt
      if (activeRun.clientRunId != null) {
        Workmanager().registerOneOffTask(
          "sync_${activeRun.clientRunId}",
          "sync_task",
          constraints: Constraints(networkType: NetworkType.connected),
        );
        
        _scheduleStreakNudge();
      }
    }

    state = RunTrackerState(
      status: 'idle',
      permissionsGranted: state.permissionsGranted,
      initialPosition: state.initialPosition,
      targetPaceSPerKm: state.targetPaceSPerKm,
      selectedShoeId: state.selectedShoeId,
    );
    _refreshLocationAfterRun();
    debugPrint('[STOP_RUN] Returning activeRun: ${activeRun?.clientRunId}');
    return activeRun;
  }

  Future<void> _scheduleStreakNudge() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final notificationService = ref.read(notificationServiceProvider);
      
      final nudgeMessage = await apiClient.getStreakNudge();
      if (nudgeMessage != null && nudgeMessage.isNotEmpty) {
        // Schedule for 24 hours from now
        final scheduleTime = DateTime.now().add(const Duration(hours: 24));
        await notificationService.scheduleStreakNudge(nudgeMessage, scheduleTime);
        debugPrint('[STREAK NUDGE] Scheduled for $scheduleTime: $nudgeMessage');
      }
    } catch (e) {
      debugPrint('[STREAK NUDGE] Error scheduling nudge: $e');
    }
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
      initialPosition: state.initialPosition,
      targetPaceSPerKm: state.targetPaceSPerKm,
    );
    _refreshLocationAfterRun();
  }

  void _refreshLocationAfterRun() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (state.status == 'idle') {
        state = state.copyWith(initialPosition: pos);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _portSubscription?.cancel();
    super.dispose();
  }
}

final runTrackerProvider = StateNotifierProvider<RunTrackerController, RunTrackerState>((ref) {
  return RunTrackerController(ref);
});

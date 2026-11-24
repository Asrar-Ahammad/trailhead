import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'location_service_task.dart';
import 'background_step_service.dart';
import '../../shoes/application/shoe_service.dart';
import 'run_analysis_service.dart';
import '../data/models/run_isar.dart';
import '../data/models/run_point_isar.dart';
import '../data/models/daily_steps_isar.dart';
import 'tracking_calcs.dart';
import '../../weather/data/weather_repository.dart';

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
  final int currentCadence;
  final int caloriesKcal;

  RunTrackerState({
    required this.status,
    this.clientRunId,
    this.distanceM = 0.0,
    this.durationS = 0,
    this.stepCount = 0,
    this.gpsWeak = false,
    this.permissionsGranted = false,
    this.permissionsChecked = true,
    this.targetPaceSPerKm,
    this.currentSplitPaceSPerKm,
    this.initialPosition,
    this.activityType = 'run',
    this.selectedShoeId,
    this.currentCadence = 0,
    this.caloriesKcal = 0,
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
    bool clearSelectedShoe = false,
    int? currentCadence,
    int? caloriesKcal,
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
      selectedShoeId: clearSelectedShoe ? null : (selectedShoeId ?? this.selectedShoeId),
      currentCadence: currentCadence ?? this.currentCadence,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    );
  }
}

class RunTrackerCubit extends Cubit<RunTrackerState> {
  final FlutterTts _flutterTts = FlutterTts();
  final Isar _isar;
  final SharedPreferences _preferences;
  final ShoeService _shoeService;
  final WeatherRepository _weatherRepository;
  final RunAnalysisService _analysisService;

  // Live tracking resources
  Timer? _runTimer;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<StepCount>? _stepSubscription;

  Position? _lastPosition;
  int _pointSequence = 0;
  double _distanceM = 0.0;
  int _durationS = 0;
  int _currentSteps = 0;
  int _stepCountOffset = -1;
  int _lastRawPedometerValue = -1;
  int _lastStepEventValueForDaily = -1;
  int _uncommittedDailySteps = 0;

  int _currentCadence = 0;
  int _cadenceWindowSteps = 0;
  DateTime? _cadenceWindowStart;

  final List<double> _altitudeBuffer = [];
  double _elevationGainM = 0.0;
  double? _lastSmoothedAltitude;

  double? _weightKg;
  double _audioCueFrequency = 1.0;
  int _lastSplitIndex = 0;
  int _lastSplitTimeS = 0;
  double _lastSplitDistanceM = 0.0;

  RunTrackerCubit({
    required Isar isar,
    required SharedPreferences preferences,
    required ShoeService shoeService,
    required WeatherRepository weatherRepository,
    required RunAnalysisService analysisService,
  }) : _isar = isar,
       _preferences = preferences,
       _shoeService = shoeService,
       _weatherRepository = weatherRepository,
       _analysisService = analysisService,
       super(RunTrackerState(status: 'idle', permissionsChecked: true)) {
    _initForegroundTask();
    _checkPermissionsSilently();
    _recoverOrphanedRuns();
    _initTts();
    _initDefaultShoe();
  }

  Future<void> _initDefaultShoe() async {
    try {
      final shoeService = _shoeService;
      final activeShoes = await shoeService.getActiveShoes();
      if (activeShoes.isNotEmpty) {
        final prefs = _preferences;
        final lastShoeId = prefs.getString('last_selected_shoe_id');
        if (lastShoeId != null && activeShoes.any((s) => s.clientShoeId == lastShoeId)) {
          emit(state.copyWith(selectedShoeId: lastShoeId));
        } else {
          emit(state.copyWith(selectedShoeId: activeShoes.first.clientShoeId));
        }
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
        channelId: 'trailhead_tracking_live',
        channelName: 'Activity Tracking',
        channelDescription: 'Shows live stats during activity tracking.',
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
  }

  void _handleSplitReached(double distance, int splitTimeS, int paceSPerKm) async {
    HapticFeedback.heavyImpact();

    final prefs = _preferences;
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
    try {
      final hasLocation = await Geolocator.checkPermission();
      final isGranted = hasLocation == LocationPermission.always ||
          hasLocation == LocationPermission.whileInUse;

      emit(state.copyWith(
        permissionsGranted: isGranted,
        permissionsChecked: true,
      ));

      if (isGranted) {
        fetchInitialLocation();
      }
    } catch (e) {
      debugPrint('[PERMISSIONS] Error checking permissions: $e');
      emit(state.copyWith(permissionsChecked: true));
    }
  }

  Future<void> recheckPermissions() => _checkPermissionsSilently();

  Future<void> fetchInitialLocation({bool force = false}) async {
    final isRunning = state.status == 'running';
    if (isRunning && !force) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS] Location service is disabled on device');
        return;
      }

      final perm = await Geolocator.checkPermission();
      final granted = perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
      if (!granted) return;

      if (!force && state.initialPosition != null) return;

      final last = await Geolocator.getLastKnownPosition();
      if (last != null && !isClosed) {
        emit(state.copyWith(initialPosition: last));
        _lastPosition = last;
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        ).then((p) {
          if (!isClosed) {
            emit(state.copyWith(initialPosition: p));
            _lastPosition = p;
          }
        }).catchError((e) {
          debugPrint('[GPS] High-accuracy upgrade failed: $e');
        });
        return;
      }

      try {
        final lowFix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 6),
          ),
        );
        if (!isClosed) {
          emit(state.copyWith(initialPosition: lowFix));
          _lastPosition = lowFix;
        }
      } catch (e) {
        debugPrint('[GPS] Low-accuracy fix failed: $e');
        try {
          final fallback = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.lowest,
              timeLimit: Duration(seconds: 5),
            ),
          );
        if (!isClosed) {
            emit(state.copyWith(initialPosition: fallback));
            _lastPosition = fallback;
          }
        } catch (_) {}
      }

      if (state.initialPosition != null) {
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        ).then((p) {
          if (!isClosed) {
            emit(state.copyWith(initialPosition: p));
            _lastPosition = p;
          }
        }).catchError((e) {
          debugPrint('[GPS] High-accuracy upgrade failed: $e');
        });
      }
    } catch (e) {
      debugPrint('[GPS] fetchInitialLocation unexpected error: $e');
    }
  }

  Future<bool> requestForegroundPermission() async {
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
          Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 3),
            ),
          ).then((p) {
            emit(state.copyWith(initialPosition: p));
            _lastPosition = p;
          }).catchError((_) {});
        } else {
          _lastPosition = pos;
        }
      } catch (_) {}
    }

    emit(state.copyWith(permissionsGranted: granted, initialPosition: pos));
    return granted;
  }

  Future<bool> requestBackgroundPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.always;

    Position? pos = state.initialPosition;
    if (granted && pos == null) {
      try {
        pos = await Geolocator.getLastKnownPosition();
        if (pos == null) {
          Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 3),
            ),
          ).then((p) {
            emit(state.copyWith(initialPosition: p));
            _lastPosition = p;
          }).catchError((_) {});
        }
      } catch (_) {}
    }

    emit(state.copyWith(permissionsGranted: granted, initialPosition: pos));
    return granted;
  }

  Future<void> _recoverOrphanedRuns() async {
    final orphanedRuns = await _isar.runIsars
        .filter()
        .statusEqualTo('running')
        .or()
        .statusEqualTo('paused')
        .findAll();

    if (orphanedRuns.isNotEmpty) {
      final activeRun = orphanedRuns.last;
      _durationS = activeRun.durationS ?? 0;
      _distanceM = activeRun.distanceM ?? 0.0;
      _elevationGainM = activeRun.elevationGainM ?? 0.0;
      _currentSteps = activeRun.stepCount ?? 0;

      emit(state.copyWith(
        status: activeRun.status,
        clientRunId: activeRun.clientRunId,
        distanceM: _distanceM,
        durationS: _durationS,
        stepCount: _currentSteps,
      ));

      if (activeRun.status == 'running') {
        _startTimerAndStreams();
      }

      if (orphanedRuns.length > 1) {
        await _isar.writeTxn(() async {
          for (var i = 0; i < orphanedRuns.length - 1; i++) {
            final run = orphanedRuns[i];
            run.status = 'completed';
            run.endTime = DateTime.now();
            run.lastModifiedAt = DateTime.now();
            await _isar.runIsars.put(run);
          }
        });
      }
    }
  }

  void setTargetPace(int? paceS) {
    emit(RunTrackerState(
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
    ));
  }

  void updateInitialPosition(Position pos) {
    emit(state.copyWith(initialPosition: pos));
    _lastPosition = pos;
  }

  void setActivityType(String type) {
    emit(state.copyWith(activityType: type));
  }

  void setSelectedShoe(String? shoeId) async {
    if (shoeId == null) {
      emit(state.copyWith(clearSelectedShoe: true));
    } else {
      emit(state.copyWith(selectedShoeId: shoeId));
    }
    try {
      final prefs = _preferences;
      if (shoeId != null) {
        await prefs.setString('last_selected_shoe_id', shoeId);
      } else {
        await prefs.remove('last_selected_shoe_id');
      }
    } catch (e) {
      debugPrint('[RUN_TRACKER] Failed to save selected shoe: $e');
    }
  }

  Future<void> startRun() async {
    if (state.status != 'idle') return;

    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}

    final prefs = _preferences;
    await prefs.setBool('run_active', true);
    _audioCueFrequency = prefs.getDouble('audio_cue_frequency') ?? 1.0;
    _weightKg = prefs.getDouble('user_weight_kg');

    final String clientRunId = const Uuid().v4();
    final DateTime now = DateTime.now();
    final activityType = state.activityType;
    final selectedShoeId = state.selectedShoeId;

    _durationS = 0;
    _distanceM = 0.0;
    _elevationGainM = 0.0;
    _currentCadence = 0;
    _currentSteps = 0;
    _stepCountOffset = -1;
    _lastRawPedometerValue = -1;
    _lastStepEventValueForDaily = -1;
    _uncommittedDailySteps = 0;
    _pointSequence = 0;
    _lastSplitIndex = 0;
    _lastSplitTimeS = 0;
    _lastSplitDistanceM = 0.0;
    _altitudeBuffer.clear();
    _lastSmoothedAltitude = null;
    _lastPosition = state.initialPosition;

    // Update state IMMEDIATELY so UI responds instantly with 00:00 and active status
    emit(RunTrackerState(
      status: 'running',
      clientRunId: clientRunId,
      distanceM: 0.0,
      durationS: 0,
      stepCount: 0,
      permissionsGranted: state.permissionsGranted,
      initialPosition: state.initialPosition,
      targetPaceSPerKm: state.targetPaceSPerKm,
      activityType: activityType,
      selectedShoeId: selectedShoeId,
    ));

    // Save initial RunIsar in database
    try {
      final newRun = RunIsar()
        ..clientRunId = clientRunId
        ..startTime = now
        ..status = 'running'
        ..activityType = activityType
        ..clientShoeId = selectedShoeId
        ..distanceM = 0.0
        ..durationS = 0;

      await _isar.writeTxn(() async {
        await _isar.runIsars.put(newRun);
      });
    } catch (e) {
      debugPrint('[START_RUN] Isar write error: $e');
    }

    // Seed initial position point if known so polyline/route starts immediately
    if (state.initialPosition != null) {
      await _recordPoint(state.initialPosition!);
    } else {
      // Eagerly try to get fix to seed route point #1
      try {
        final fix = await Geolocator.getLastKnownPosition();
        if (fix != null) {
          emit(state.copyWith(initialPosition: fix));
          _lastPosition = fix;
          await _recordPoint(fix);
        }
      } catch (_) {}
    }

    // Start Timer, Location Stream, and Pedometer Stream
    _startTimerAndStreams();

    // Start background foreground service for notification & wake-lock
    _startForegroundServiceSafely(clientRunId);

    // Fetch weather in background
    Future.microtask(() async {
      try {
        final weatherRepo = _weatherRepository;
        final weatherData = await weatherRepo.getCurrentWeather();
        if (weatherData != null) {
          await _isar.writeTxn(() async {
            final existingRun = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
            if (existingRun != null) {
              existingRun.weatherTemp = (weatherData['temperature'] as num?)?.toDouble();
              existingRun.weatherCode = (weatherData['weathercode'] as num?)?.toDouble();
              await _isar.runIsars.put(existingRun);
            }
          });
        }
      } catch (_) {}
    });
  }

  void _startTimerAndStreams() {
    // 1-second live run timer
    _runTimer?.cancel();
    _cadenceWindowStart = DateTime.now();
    _cadenceWindowSteps = _currentSteps;

    _runTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == 'running') {
        _durationS++;

        // Rolling cadence check
        final now = DateTime.now();
        _cadenceWindowStart ??= now;
        final windowSeconds = now.difference(_cadenceWindowStart!).inSeconds;
        if (windowSeconds >= 5) {
          final deltaSteps = _currentSteps - _cadenceWindowSteps;
          final computed = ((deltaSteps / windowSeconds) * 60).round();
          _currentCadence = (computed >= 60 && computed <= 300) ? computed : 0;
          _cadenceWindowSteps = _currentSteps;
          _cadenceWindowStart = now;
        }

        final calories = TrackingCalcs.estimateCalories(
          weightKg: _weightKg,
          distanceM: _distanceM,
          durationS: _durationS,
        )?.toInt() ?? 0;

        emit(state.copyWith(
          durationS: _durationS,
          caloriesKcal: calories,
          currentCadence: _currentCadence,
        ));

        _updateForegroundNotification();

        if (_durationS % 5 == 0) {
          _persistRunMetadata();
        }
      }
    });

    // Start GPS stream
    _locationSubscription?.cancel();
    final LocationSettings locationSettings = Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
            pauseLocationUpdatesAutomatically: false,
            activityType: ActivityType.fitness,
            allowBackgroundLocationUpdates: true,
            showBackgroundLocationIndicator: true,
          )
        : AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
            intervalDuration: const Duration(seconds: 1),
          );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handleLocationUpdate,
      onError: (e) {
        debugPrint('[GPS_STREAM] Error: $e');
      },
    );

    // Start Pedometer stream
    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen(
      _handleStepUpdate,
      onError: (_) {},
    );
  }

  Future<void> _startForegroundServiceSafely(String clientRunId) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        for (var i = 0; i < 10; i++) {
          if (!await FlutterForegroundTask.isRunningService) break;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      _initForegroundTask();

      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.location],
        notificationTitle: 'Run in Progress',
        notificationText: '0.00 km • -:-- /km • 00:00',
        callback: startCallback,
      );
    } catch (e) {
      debugPrint('[FOREGROUND_SERVICE] Error starting service: $e');
    }
  }

  void _handleLocationUpdate(Position position) async {
    final clientRunId = state.clientRunId;
    if (clientRunId == null) return;

    // Check accuracy — threshold relaxed to 65m to avoid dropping early/indoor fixes
    final bool poorAccuracy = position.accuracy > 65.0;
    if (state.gpsWeak != poorAccuracy) {
      emit(state.copyWith(gpsWeak: poorAccuracy));
    }
    if (poorAccuracy) return;

    double speed = position.speed;
    double deltaDist = 0.0;

    if (_lastPosition != null) {
      deltaDist = TrackingCalcs.calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      final double deltaTimeS = (position.timestamp.difference(_lastPosition!.timestamp).inMilliseconds) / 1000.0;

      if (TrackingCalcs.isGpsJump(deltaDist, deltaTimeS, position.accuracy, maxAccuracy: 65.0)) {
        _lastPosition = position;
        return;
      }

      if (deltaTimeS > 0.0 && speed <= 0.0) {
        speed = deltaDist / deltaTimeS;
      }
    }

    if (state.status == 'running') {
      // Record point if it's the first fix or has moved at least 0.5 meters
      if (_lastPosition == null || deltaDist >= 0.5) {
        _distanceM += deltaDist;
        _lastPosition = position;

        // Altitude smoothing
        _altitudeBuffer.add(position.altitude);
        if (_altitudeBuffer.length > 3) {
          _altitudeBuffer.removeAt(0);
        }
        if (_altitudeBuffer.length == 3) {
          final double smoothed = _altitudeBuffer.reduce((a, b) => a + b) / 3.0;
          if (_lastSmoothedAltitude != null) {
            final double deltaAlt = smoothed - _lastSmoothedAltitude!;
            if (deltaAlt > 0) {
              _elevationGainM += deltaAlt;
            }
          }
          _lastSmoothedAltitude = smoothed;
        }

        await _recordPoint(position, speed: speed);

        // Split tracking & audio cues
        final double distanceKm = _distanceM / 1000.0;
        final int currentSplitIndex = (distanceKm / _audioCueFrequency).floor();
        if (currentSplitIndex > _lastSplitIndex) {
          final int splitTimeS = _durationS - _lastSplitTimeS;
          final double splitDistanceKm = (_distanceM - _lastSplitDistanceM) / 1000.0;
          final int splitPaceSPerKm = splitDistanceKm > 0 ? (splitTimeS / splitDistanceKm).round() : 0;
          _handleSplitReached(currentSplitIndex * _audioCueFrequency, splitTimeS, splitPaceSPerKm);
          _lastSplitIndex = currentSplitIndex;
          _lastSplitTimeS = _durationS;
          _lastSplitDistanceM = _distanceM;
        }

        int? currentSplitPace;
        if (_distanceM > _lastSplitDistanceM && _durationS > _lastSplitTimeS) {
          final double currentSplitDistKm = (_distanceM - _lastSplitDistanceM) / 1000.0;
          if (currentSplitDistKm > 0) {
            currentSplitPace = ((_durationS - _lastSplitTimeS) / currentSplitDistKm).round();
          }
        }

        final calories = TrackingCalcs.estimateCalories(
          weightKg: _weightKg,
          distanceM: _distanceM,
          durationS: _durationS,
        )?.toInt() ?? 0;

        emit(state.copyWith(
          distanceM: _distanceM,
          initialPosition: position,
          currentSplitPaceSPerKm: currentSplitPace,
          caloriesKcal: calories,
        ));

        _updateForegroundNotification();
      }
    } else {
      _lastPosition = position;
      emit(state.copyWith(initialPosition: position));
    }
  }

  Future<void> _recordPoint(Position position, {double? speed}) async {
    final clientRunId = state.clientRunId;
    if (clientRunId == null) return;
    try {
      _pointSequence++;
      final point = RunPointIsar()
        ..clientRunId = clientRunId
        ..lat = position.latitude
        ..lng = position.longitude
        ..elevation = position.altitude
        ..timestamp = position.timestamp
        ..accuracy = position.accuracy
        ..speed = speed ?? position.speed
        ..cadence = _currentCadence
        ..isPaused = state.status == 'paused'
        ..sequence = _pointSequence;

      await _isar.writeTxn(() async {
        await _isar.runPointIsars.put(point);
      });
    } catch (e) {
      debugPrint('[RECORD_POINT] Error: $e');
    }
  }

  void _handleStepUpdate(StepCount event) {
    _lastRawPedometerValue = event.steps;

    if (_lastStepEventValueForDaily == -1) {
      _lastStepEventValueForDaily = event.steps;
    }
    final delta = max(0, event.steps - _lastStepEventValueForDaily);
    _lastStepEventValueForDaily = event.steps;
    _uncommittedDailySteps += delta;

    if (_uncommittedDailySteps >= 50) {
      _persistDailySteps(deltaSteps: _uncommittedDailySteps, rawPedometerValue: event.steps);
      _uncommittedDailySteps = 0;
    }

    if (state.status != 'running') return;

    if (_stepCountOffset == -1) {
      _stepCountOffset = event.steps;
    }

    _currentSteps = max(0, event.steps - _stepCountOffset);
    emit(state.copyWith(stepCount: _currentSteps));
  }

  Future<void> _persistDailySteps({required int deltaSteps, required int rawPedometerValue}) async {
    try {
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final existing = await _isar.dailyStepsIsars.filter().dateKeyEqualTo(dateKey).findFirst();
      await _isar.writeTxn(() async {
        if (existing != null) {
          existing.steps += deltaSteps;
          List<int> hSteps = existing.hourlySteps.toList();
          if (hSteps.length != 24) hSteps = List.filled(24, 0);
          hSteps[now.hour] += deltaSteps;
          existing.hourlySteps = hSteps;
          existing.lastPedometerValue = rawPedometerValue;
          existing.lastUpdated = DateTime.now();
          await _isar.dailyStepsIsars.put(existing);
        } else {
          final hSteps = List.filled(24, 0);
          hSteps[now.hour] = deltaSteps;
          final record = DailyStepsIsar()
            ..dateKey = dateKey
            ..steps = deltaSteps
            ..hourlySteps = hSteps
            ..lastPedometerValue = rawPedometerValue
            ..lastUpdated = DateTime.now();
          await _isar.dailyStepsIsars.put(record);
        }
      });
    } catch (_) {}
  }

  void _persistRunMetadata() async {
    final clientRunId = state.clientRunId;
    if (clientRunId == null) return;

    try {
      final activeRun = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
      if (activeRun != null) {
        activeRun.distanceM = _distanceM;
        activeRun.durationS = _durationS;
        activeRun.stepCount = _currentSteps;
        activeRun.elevationGainM = _elevationGainM;

        if (_currentSteps > 0) {
          activeRun.avgStrideLengthM = _distanceM / _currentSteps;
          activeRun.avgCadenceSpm = _durationS > 0 ? _currentSteps / (_durationS / 60.0) : 0;
        }

        activeRun.caloriesKcal = TrackingCalcs.estimateCalories(
          weightKg: _weightKg,
          distanceM: _distanceM,
          durationS: _durationS,
        );

        if (_distanceM > 0) {
          activeRun.avgPaceSPerKm = _durationS / (_distanceM / 1000.0);
        }

        await _isar.writeTxn(() async {
          await _isar.runIsars.put(activeRun);
        });
      }
    } catch (_) {}
  }

  void _updateForegroundNotification() {
    try {
      final double distanceKm = _distanceM / 1000.0;
      final String distStr = distanceKm.toStringAsFixed(2);
      final int paceS = distanceKm > 0 ? (_durationS / distanceKm).round() : 0;
      final int paceMin = paceS ~/ 60;
      final int paceSec = paceS % 60;
      final String paceStr = distanceKm > 0
          ? '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')}'
          : '-:--';
      final int hours = _durationS ~/ 3600;
      final int mins = (_durationS % 3600) ~/ 60;
      final int secs = _durationS % 60;
      final String durationStr = hours > 0
          ? '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
          : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

      FlutterForegroundTask.updateService(
        notificationTitle: state.status == 'paused' ? 'Run Paused' : 'Run in Progress',
        notificationText: '$distStr km • $paceStr /km • $durationStr',
      );
    } catch (_) {}
  }

  Future<void> pauseRun() async {
    if (state.status != 'running') return;

    emit(state.copyWith(status: 'paused'));
    _updateForegroundNotification();

    final clientRunId = state.clientRunId;
    Future.microtask(() async {
      try {
        final activeRun = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
        if (activeRun != null) {
          activeRun.status = 'paused';
          activeRun.durationS = _durationS;
          activeRun.distanceM = _distanceM;
          await _isar.writeTxn(() async {
            await _isar.runIsars.put(activeRun);
          });
        }
      } catch (e) {
        debugPrint('[PAUSE_RUN] Isar write error: $e');
      }
    });
  }

  Future<void> resumeRun() async {
    if (state.status != 'paused') return;

    emit(state.copyWith(status: 'running'));
    _updateForegroundNotification();

    final clientRunId = state.clientRunId;
    Future.microtask(() async {
      try {
        final activeRun = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
        if (activeRun != null) {
          activeRun.status = 'running';
          await _isar.writeTxn(() async {
            await _isar.runIsars.put(activeRun);
          });
        }
      } catch (e) {
        debugPrint('[RESUME_RUN] Isar write error: $e');
      }
    });
  }

  Future<RunIsar?> stopRun() async {
    debugPrint('[STOP_RUN] Called. state.status=${state.status}, clientRunId=${state.clientRunId}');
    if (state.status != 'running' && state.status != 'paused') {
      debugPrint('[STOP_RUN] EARLY RETURN - status is ${state.status}, not running or paused');
      return null;
    }

    _runTimer?.cancel();
    _locationSubscription?.cancel();
    _stepSubscription?.cancel();

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('[STOP_RUN] Error stopping foreground service: $e');
    }

    _clearRunFlagAndRestartStepCounter();

    final activeRun = await _isar.runIsars.filter().clientRunIdEqualTo(state.clientRunId).findFirst();
    if (activeRun != null) {
      activeRun.status = 'completed';
      activeRun.endTime = DateTime.now();
      activeRun.durationS = _durationS;
      activeRun.distanceM = _distanceM;
      activeRun.elevationGainM = _elevationGainM;
      activeRun.stepCount = _currentSteps;
      activeRun.caloriesKcal = TrackingCalcs.estimateCalories(
        weightKg: _weightKg,
        distanceM: _distanceM,
        durationS: _durationS,
      );

      if (_currentSteps > 0) {
        activeRun.avgStrideLengthM = _distanceM / _currentSteps;
        activeRun.avgCadenceSpm = _durationS > 0 ? _currentSteps / (_durationS / 60.0) : 0;
      }

      if (_distanceM > 0) {
        activeRun.avgPaceSPerKm = _durationS / (_distanceM / 1000.0);
      }

      activeRun.clientShoeId = state.selectedShoeId;
      activeRun.lastModifiedAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.runIsars.put(activeRun);
      });
    }

    emit(RunTrackerState(
      status: 'idle',
      permissionsGranted: state.permissionsGranted,
      initialPosition: state.initialPosition,
      targetPaceSPerKm: state.targetPaceSPerKm,
      selectedShoeId: state.selectedShoeId,
    ));

    _initDefaultShoe();

    if (activeRun != null) {
      Future.microtask(() async {
        try {
          final analysisService = _analysisService;
          await analysisService.refreshPerformanceSummary();
          await analysisService.generateAnalysisForRun(activeRun);
        } catch (e) {
          debugPrint('[STOP_RUN] AI Analysis background error: $e');
        }
      });
    }

    _refreshLocationAfterRun();
    debugPrint('[STOP_RUN] Returning activeRun: ${activeRun?.clientRunId}');
    return activeRun;
  }

  Future<void> discardRun() async {
    if (state.clientRunId == null) return;

    final clientRunId = state.clientRunId!;

    _runTimer?.cancel();
    _locationSubscription?.cancel();
    _stepSubscription?.cancel();

    emit(RunTrackerState(
      status: 'idle',
      permissionsGranted: state.permissionsGranted,
      initialPosition: state.initialPosition,
      targetPaceSPerKm: state.targetPaceSPerKm,
    ));

    _initDefaultShoe();

    Future.microtask(() async {
      try {
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
      } catch (e) {
        debugPrint('[DISCARD_RUN] Error stopping foreground service: $e');
      }

      _clearRunFlagAndRestartStepCounter();

      try {
        await _isar.writeTxn(() async {
          final run = await _isar.runIsars.filter().clientRunIdEqualTo(clientRunId).findFirst();
          if (run != null) {
            await _isar.runIsars.delete(run.id);
          }
          final points = await _isar.runPointIsars.filter().clientRunIdEqualTo(clientRunId).findAll();
          for (final p in points) {
            await _isar.runPointIsars.delete(p.id);
          }
        });
      } catch (e) {
        debugPrint('[DISCARD_RUN] Isar cleanup error: $e');
      }
    });

    _refreshLocationAfterRun();
  }

  void _refreshLocationAfterRun() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (state.status == 'idle') {
        emit(state.copyWith(initialPosition: pos));
        _lastPosition = pos;
      }
    } catch (_) {}
  }

  void _clearRunFlagAndRestartStepCounter() async {
    try {
      final prefs = _preferences;
      await prefs.setBool('run_active', false);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'trailhead_steps',
          channelName: 'Step Counter',
          channelDescription: 'Counts your steps in the background.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(60000),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
        ),
      );

      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        await FlutterForegroundTask.startService(
          serviceTypes: [ForegroundServiceTypes.health],
          notificationTitle: 'Trailhead',
          notificationText: '0 steps today',
          callback: backgroundStepCallback,
        );
      }
    } catch (e) {
      debugPrint('[STEP_COUNTER] Error restarting step counter: $e');
    }
  }

  @override
  Future<void> close() async {
    _runTimer?.cancel();
    await _locationSubscription?.cancel();
    await _stepSubscription?.cancel();
    await super.close();
  }
}

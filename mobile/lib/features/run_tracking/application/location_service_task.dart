import 'dart:async';
import 'dart:math';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:trailhead_mobile/features/shoes/data/models/shoe_isar.dart';
import '../data/models/run_isar.dart';
import '../data/models/run_point_isar.dart';
import '../../sync/data/models/sync_job_isar.dart';
import 'tracking_calcs.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  Isar? _isar;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<StepCount>? _stepSubscription;
  
  String? _clientRunId;
  int _durationS = 0;
  double _distanceM = 0.0;
  int _stepCountOffset = -1;
  int _currentSteps = 0;
  bool _isPaused = false;
  
  int _lastPointSteps = 0;
  DateTime? _lastPointTime;
  int _currentCadence = 0;
  
  Position? _lastPosition;
  Timer? _timer;
  
  int _lastSplitIndex = 0;
  int _lastSplitTimeS = 0;
  double _lastSplitDistanceM = 0.0;
  double _audioCueFrequency = 1.0;
  
  // Elevation smoothing
  final List<double> _altitudeBuffer = [];
  double _elevationGainM = 0.0;
  double? _lastSmoothedAltitude;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = Isar.getInstance() ?? await Isar.open(
      [RunIsarSchema, RunPointIsarSchema, SyncJobIsarSchema, ShoeIsarSchema],
      directory: dir.path,
    );

    // Find the active run
    final activeRun = await _isar!.runIsars.filter().statusEqualTo('running').findFirst();
    if (activeRun == null) {
      FlutterForegroundTask.stopService();
      return;
    }

    _clientRunId = activeRun.clientRunId;
    _durationS = activeRun.durationS ?? 0;
    _distanceM = activeRun.distanceM ?? 0.0;
    _elevationGainM = activeRun.elevationGainM ?? 0.0;
    _isPaused = false;
    
    _lastPointSteps = _currentSteps;
    _lastPointTime = DateTime.now();
    _currentCadence = 0;
    
    final prefs = await SharedPreferences.getInstance();
    _audioCueFrequency = prefs.getDouble('audio_cue_frequency') ?? 1.0;

    _lastSplitIndex = ((_distanceM / 1000.0) / _audioCueFrequency).floor();
    _lastSplitDistanceM = _distanceM;
    _lastSplitTimeS = _durationS;

    // Retrieve last position if there are already points for this run
    final lastPoint = await _isar!.runPointIsars
        .filter()
        .clientRunIdEqualTo(_clientRunId)
        .sortBySequenceDesc()
        .findFirst();
    if (lastPoint != null) {
      _lastPosition = Position(
        latitude: lastPoint.lat ?? 0.0,
        longitude: lastPoint.lng ?? 0.0,
        timestamp: lastPoint.timestamp ?? DateTime.now(),
        accuracy: lastPoint.accuracy ?? 0.0,
        altitude: lastPoint.elevation ?? 0.0,
        heading: 0.0,
        speed: lastPoint.speed ?? 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    // Start location updates stream
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Receive update when moving 5 meters
        intervalDuration: const Duration(seconds: 2),
      ),
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });

    // Start pedometer stream (for step counts)
    _stepSubscription = Pedometer.stepCountStream.listen((StepCount event) {
      _handleStepUpdate(event);
    }, onError: (error) {
      // Ignore sensor issues
    });

    // Start 1-second timer for duration increment
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _durationS++;
        _updateUIAndNotification();
        // Persist metadata to DB every 5 seconds to minimize writes
        if (_durationS % 5 == 0) {
          _persistRunMetadata();
        }
      }
    });
  }

  void _handleLocationUpdate(Position position) async {
    if (_isar == null || _clientRunId == null) return;

    // Filter by accuracy (reject points with accuracy > 20m)
    if (position.accuracy > 20.0) {
      FlutterForegroundTask.sendDataToMain({
        'type': 'gps_weak',
        'weak': true,
      });
      return;
    }

    FlutterForegroundTask.sendDataToMain({
      'type': 'gps_weak',
      'weak': false,
    });

    double speed = position.speed;
    double deltaDist = 0.0;

    if (_lastPosition != null) {
      // Calculate delta distance
      deltaDist = TrackingCalcs.calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      final double deltaTimeS = (position.timestamp.difference(_lastPosition!.timestamp).inMilliseconds) / 1000.0;

      if (TrackingCalcs.isGpsJump(deltaDist, deltaTimeS, position.accuracy)) {
        return;
      }

      if (deltaTimeS > 0.0 && speed <= 0.0) {
        speed = deltaDist / deltaTimeS;
      }
    }

    _lastPosition = position;

    // Only update distance and add point if not paused
    if (!_isPaused) {
      _distanceM += deltaDist;
      
      // Calculate smoothed elevation
      _altitudeBuffer.add(position.altitude);
      if (_altitudeBuffer.length > 3) {
        _altitudeBuffer.removeAt(0);
      }
      
      if (_altitudeBuffer.length == 3) {
        final double smoothedAltitude = _altitudeBuffer.reduce((a, b) => a + b) / 3.0;
        if (_lastSmoothedAltitude != null) {
          final double deltaAlt = smoothedAltitude - _lastSmoothedAltitude!;
          if (deltaAlt > 0) {
            _elevationGainM += deltaAlt;
          }
        }
        _lastSmoothedAltitude = smoothedAltitude;
      }

      // Calculate instantaneous cadence
      if (_lastPointTime != null) {
        final double deltaSeconds = position.timestamp.difference(_lastPointTime!).inMilliseconds / 1000.0;
        if (deltaSeconds >= 2.0) { // Update over a reasonable window
          final int deltaSteps = _currentSteps - _lastPointSteps;
          _currentCadence = ((deltaSteps / deltaSeconds) * 60).round();
          // Cadence caps (walking/running usually 60-250)
          if (_currentCadence > 300) _currentCadence = 0;
          _lastPointSteps = _currentSteps;
          _lastPointTime = position.timestamp;
        }
      } else {
        _lastPointTime = position.timestamp;
        _lastPointSteps = _currentSteps;
      }

      // Save point to local database
      final count = await _isar!.runPointIsars.filter().clientRunIdEqualTo(_clientRunId).count();
      final point = RunPointIsar()
        ..clientRunId = _clientRunId
        ..lat = position.latitude
        ..lng = position.longitude
        ..elevation = position.altitude
        ..timestamp = position.timestamp
        ..accuracy = position.accuracy
        ..speed = speed
        ..cadence = _currentCadence
        ..isPaused = false
        ..sequence = count + 1;

      await _isar!.writeTxn(() async {
        await _isar!.runPointIsars.put(point);
      });
      
      _updateUIAndNotification();
    }
  }

  void _handleStepUpdate(StepCount event) {
    if (_isPaused) return;

    if (_stepCountOffset == -1) {
      _stepCountOffset = event.steps;
    }

    _currentSteps = max(0, event.steps - _stepCountOffset);
    _updateUIAndNotification();
  }

  void _persistRunMetadata() async {
    if (_isar == null || _clientRunId == null) return;
    
    final activeRun = await _isar!.runIsars.filter().clientRunIdEqualTo(_clientRunId).findFirst();
    if (activeRun != null) {
      activeRun.distanceM = _distanceM;
      activeRun.durationS = _durationS;
      activeRun.stepCount = _currentSteps;
      activeRun.elevationGainM = _elevationGainM;
      
      if (_currentSteps > 0) {
        activeRun.avgStrideLengthM = _distanceM / _currentSteps;
        activeRun.avgCadenceSpm = _currentSteps / (_durationS / 60.0);
      }
      
      // Estimate Calories
      final prefs = await SharedPreferences.getInstance();
      final weight = prefs.getDouble('user_weight_kg');
      activeRun.caloriesKcal = TrackingCalcs.estimateCalories(
        weightKg: weight,
        distanceM: _distanceM,
        durationS: _durationS,
      );
      
      if (_distanceM > 0) {
        activeRun.avgPaceSPerKm = _durationS / (_distanceM / 1000.0);
      }

      await _isar!.writeTxn(() async {
        await _isar!.runIsars.put(activeRun);
      });
    }
  }

  void _updateUIAndNotification() {
    // Format duration: hh:mm:ss or mm:ss
    final String durationString = _formatDuration(_durationS);
    
    // Format distance: km with 2 decimals
    final double distanceKm = _distanceM / 1000.0;
    final String distanceString = distanceKm.toStringAsFixed(2);
    
    // Calculate current pace (min/km)
    String paceString = "-:--";
    if (_distanceM > 0) {
      final double paceS = _durationS / distanceKm;
      final int paceMin = (paceS / 60).floor();
      final int paceSec = (paceS % 60).round();
      paceString = "${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')}";
    }

    final String notificationText = "$distanceString km • $paceString /km • $durationString";
    
    FlutterForegroundTask.updateService(
      notificationTitle: _isPaused ? "Run Paused" : "Run in Progress",
      notificationText: notificationText,
    );

    // Split detection
    final int currentSplitIndex = (distanceKm / _audioCueFrequency).floor();
    if (currentSplitIndex > _lastSplitIndex) {
      final int splitTimeS = _durationS - _lastSplitTimeS;
      final double splitDistanceKm = (_distanceM - _lastSplitDistanceM) / 1000.0;
      final int splitPaceSPerKm = splitDistanceKm > 0 ? (splitTimeS / splitDistanceKm).round() : 0;
      
      FlutterForegroundTask.sendDataToMain({
        'type': 'split_reached',
        'splitDistance': currentSplitIndex * _audioCueFrequency,
        'timeS': splitTimeS,
        'paceSPerKm': splitPaceSPerKm,
      });
      
      _lastSplitIndex = currentSplitIndex;
      _lastSplitTimeS = _durationS;
      _lastSplitDistanceM = _distanceM;
    }

    // Current Split Pace
    int? currentSplitPace;
    if (_distanceM > _lastSplitDistanceM && _durationS > _lastSplitTimeS) {
      final double currentSplitDistKm = (_distanceM - _lastSplitDistanceM) / 1000.0;
      if (currentSplitDistKm > 0) {
        currentSplitPace = ((_durationS - _lastSplitTimeS) / currentSplitDistKm).round();
      }
    }

    // Send data to UI isolate
    FlutterForegroundTask.sendDataToMain({
      'type': 'stats_update',
      'clientRunId': _clientRunId,
      'durationS': _durationS,
      'distanceM': _distanceM,
      'stepCount': _currentSteps,
      'elevationGainM': _elevationGainM,
      'isPaused': _isPaused,
      'currentSplitPaceSPerKm': currentSplitPace,
    });
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not used as we run a periodic timer for precision, but required by API
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
    await _locationSubscription?.cancel();
    await _stepSubscription?.cancel();
    _persistRunMetadata();
  }

  @pragma('vm:entry-point')
  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final action = data['action'];
      if (action == 'pause') {
        _isPaused = true;
      } else if (action == 'resume') {
        _isPaused = false;
      } else if (action == 'update_settings') {
        _audioCueFrequency = (data['audioCueFrequency'] as num).toDouble();
        final double distanceKm = _distanceM / 1000.0;
        _lastSplitIndex = (distanceKm / _audioCueFrequency).floor();
      }
    }
  }
}

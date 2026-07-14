import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/run_isar.dart';
import '../data/models/run_point_isar.dart';
import '../data/models/daily_steps_isar.dart';
import '../../sync/data/models/sync_job_isar.dart';
import '../../shoes/data/models/shoe_isar.dart';

@pragma('vm:entry-point')
void backgroundStepCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundStepTaskHandler());
}

class BackgroundStepTaskHandler extends TaskHandler {
  Isar? _isar;
  StreamSubscription<StepCount>? _stepSubscription;
  int _lastRawSteps = -1;
  String _currentDateKey = '';
  int _todaySteps = 0;

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = Isar.getInstance() ?? await Isar.open(
      [RunIsarSchema, RunPointIsarSchema, SyncJobIsarSchema, ShoeIsarSchema, DailyStepsIsarSchema],
      directory: dir.path,
    );

    _currentDateKey = _dateKey(DateTime.now());

    // Load last known pedometer value and today's steps from DB
    final existing = await _isar!.dailyStepsIsars
        .filter()
        .dateKeyEqualTo(_currentDateKey)
        .findFirst();
    if (existing != null) {
      _todaySteps = existing.steps;
      _lastRawSteps = existing.lastPedometerValue;
    }

    // Start pedometer stream
    _stepSubscription = Pedometer.stepCountStream.listen(
      _handleStepUpdate,
      onError: (error) {
        // Pedometer not available on this device — silently ignore
      },
    );
  }

  void _handleStepUpdate(StepCount event) async {
    if (_isar == null) return;

    // Check if a run is active — skip accumulation to avoid double-counting
    final prefs = await SharedPreferences.getInstance();
    final runActive = prefs.getBool('run_active') ?? false;
    if (runActive) {
      // Update the raw pedometer reference so we don't get a huge spike when the run ends
      _lastRawSteps = event.steps;
      return;
    }

    final now = DateTime.now();
    final todayKey = _dateKey(now);

    // Handle day rollover
    if (todayKey != _currentDateKey) {
      _currentDateKey = todayKey;
      _todaySteps = 0;
      _lastRawSteps = event.steps; // Reset baseline for new day
      // Create new day record
      await _persistSteps(event.steps);
      return;
    }

    // First reading after startup — just set baseline
    if (_lastRawSteps == -1) {
      _lastRawSteps = event.steps;
      return;
    }

    // Calculate delta (handle pedometer reset where new value < old)
    int delta = event.steps - _lastRawSteps;
    if (delta < 0) {
      // Pedometer was reset (e.g. device reboot) — treat current as absolute
      delta = 0;
      _lastRawSteps = event.steps;
      return;
    }

    if (delta > 0) {
      _todaySteps += delta;
      _lastRawSteps = event.steps;
      await _persistSteps(event.steps);
    }
  }

  Future<void> _persistSteps(int rawPedometerValue) async {
    if (_isar == null) return;

    try {
      final existing = await _isar!.dailyStepsIsars
          .filter()
          .dateKeyEqualTo(_currentDateKey)
          .findFirst();

      await _isar!.writeTxn(() async {
        if (existing != null) {
          existing.steps = _todaySteps;
          existing.lastPedometerValue = rawPedometerValue;
          existing.lastUpdated = DateTime.now();
          await _isar!.dailyStepsIsars.put(existing);
        } else {
          final record = DailyStepsIsar()
            ..dateKey = _currentDateKey
            ..steps = _todaySteps
            ..lastPedometerValue = rawPedometerValue
            ..lastUpdated = DateTime.now();
          await _isar!.dailyStepsIsars.put(record);
        }
      });
    } catch (e) {
      // Silently fail — next update will persist
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Update notification with current step count (called every 60 seconds)
    FlutterForegroundTask.updateService(
      notificationTitle: 'Trailhead',
      notificationText: '$_todaySteps steps today',
    );

    // Handle day rollover on timer tick too
    final nowKey = _dateKey(DateTime.now());
    if (nowKey != _currentDateKey) {
      _currentDateKey = nowKey;
      _todaySteps = 0;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _stepSubscription?.cancel();
    // Final persist
    if (_lastRawSteps >= 0) {
      await _persistSteps(_lastRawSteps);
    }
  }

  @pragma('vm:entry-point')
  @override
  void onReceiveData(Object data) {
    // No commands needed for this service
  }
}

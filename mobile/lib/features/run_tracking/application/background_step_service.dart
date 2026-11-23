import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/run_isar.dart';
import '../data/models/run_point_isar.dart';
import '../data/models/daily_steps_isar.dart';
import '../../shoes/data/models/shoe_isar.dart';
import '../../../main.dart'; // import global isarInstance schemas
import '../../stats/data/models/personal_record_isar.dart';
import '../../stats/data/models/weekly_report_isar.dart';
import '../../goals/data/models/goal_isar.dart';


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
  List<int> _hourlySteps = List.filled(24, 0);

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = Isar.getInstance() ?? await Isar.open(
        [
          RunIsarSchema,
          RunPointIsarSchema,
          ShoeIsarSchema,
          DailyStepsIsarSchema,
          PersonalRecordIsarSchema,
          WeeklyReportIsarSchema,
          GoalIsarSchema,
        ],
        directory: dir.path,
        inspector: false,
      );
    } catch (e) {
      // Isar instance may already be open or in use
    }

    _currentDateKey = _dateKey(DateTime.now());

    // Load last known pedometer value and today's steps from DB
    final existing = await _isar!.dailyStepsIsars
        .filter()
        .dateKeyEqualTo(_currentDateKey)
        .findFirst();
    if (existing != null) {
      _todaySteps = existing.steps;
      _lastRawSteps = existing.lastPedometerValue;
      if (existing.hourlySteps.length == 24) {
        _hourlySteps = existing.hourlySteps.toList();
      }
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
      _hourlySteps = List.filled(24, 0);
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
      _hourlySteps[now.hour] += delta;
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
          existing.hourlySteps = _hourlySteps.toList();
          existing.lastPedometerValue = rawPedometerValue;
          existing.lastUpdated = DateTime.now();
          await _isar!.dailyStepsIsars.put(existing);
        } else {
          final record = DailyStepsIsar()
            ..dateKey = _currentDateKey
            ..steps = _todaySteps
            ..hourlySteps = _hourlySteps.toList()
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
  void onRepeatEvent(DateTime timestamp) async {
    // Handle day rollover on timer tick too
    final nowKey = _dateKey(DateTime.now());
    if (nowKey != _currentDateKey) {
      _currentDateKey = nowKey;
      _todaySteps = 0;
    }

    int displaySteps = _todaySteps;

    if (_isar != null) {
      final existing = await _isar!.dailyStepsIsars
          .filter()
          .dateKeyEqualTo(_currentDateKey)
          .findFirst();
      if (existing != null) {
        _todaySteps = existing.steps;
        displaySteps = existing.steps;
      }

      // While a run is active the background step service skips accumulation
      // to avoid double-counting. The run tracking service writes the in-run
      // step count directly to the RunIsar record. Add those steps so the
      // notification reflects the true total (daily steps + current run steps).
      final prefs = await SharedPreferences.getInstance();
      final runActive = prefs.getBool('run_active') ?? false;
      if (runActive) {
        final activeRun = await _isar!.runIsars
            .filter()
            .statusEqualTo('running')
            .or()
            .statusEqualTo('paused')
            .findFirst();
        if (activeRun != null && (activeRun.stepCount ?? 0) > 0) {
          displaySteps += activeRun.stepCount ?? 0;
        }
      }
    }

    // Update notification with current step count (called every 60 seconds)
    FlutterForegroundTask.updateService(
      notificationTitle: 'Trailhead',
      notificationText: '$displaySteps steps today',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
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

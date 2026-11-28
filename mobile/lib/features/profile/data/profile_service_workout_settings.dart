import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ProfileWorkoutSettingsService {
  void updateCueFrequency(double value) {
    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'update_settings',
        'audioCueFrequency': value,
      });
    } catch (_) {
      // The next tracking session reads the persisted value.
    }
  }
}

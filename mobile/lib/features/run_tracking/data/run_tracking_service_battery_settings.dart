import 'dart:io';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

class RunBatterySettingsService {
  Future<void> promptIfNeeded() async {
    if (!Platform.isAndroid) return;
    try {
      if (await DisableBatteryOptimization.isBatteryOptimizationDisabled ==
          false) {
        await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      }
    } catch (_) {
      // The OS may not provide an exemption screen on every device.
    }
  }
}

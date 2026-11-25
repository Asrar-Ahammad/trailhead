import 'package:shared_preferences/shared_preferences.dart';

import '../domain/haptics_repository_feedback.dart';
import 'haptics_service_feedback.dart';

class HapticsRepositoryImplementation implements HapticsRepository {
  const HapticsRepositoryImplementation(this._preferences, this._service);

  static const _enabledKey = 'haptics_enabled';
  final SharedPreferences _preferences;
  final HapticsFeedbackService _service;

  @override
  bool get isEnabled => _preferences.getBool(_enabledKey) ?? true;

  @override
  Future<bool> setEnabled(bool enabled) =>
      _preferences.setBool(_enabledKey, enabled);

  @override
  Future<void> play(HapticEffect effect) => _service.play(effect);
}

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/audio_repository_ui_sounds.dart';
import 'audio_service_ui_sounds.dart';

class AudioRepositoryImplementation implements AudioRepository {
  const AudioRepositoryImplementation(this._preferences, this._service);

  static const _enabledKey = 'ui_sounds_enabled';
  final SharedPreferences _preferences;
  final AudioUiSoundService _service;

  @override
  bool get isEnabled => _preferences.getBool(_enabledKey) ?? false;

  @override
  Future<bool> setEnabled(bool enabled) =>
      _preferences.setBool(_enabledKey, enabled);

  @override
  Future<void> play(AudioCue cue) => _service.play(cue);
}

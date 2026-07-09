import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final soundServiceProvider = Provider((ref) => SoundService());

class SoundService {
  final AudioPlayer _navPlayer = AudioPlayer();
  final AudioPlayer _actionPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();

  bool? _uiSoundsEnabled;

  SoundService() {
    // Fire and forget, but methods will await if not done
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _uiSoundsEnabled = prefs.getBool('ui_sounds_enabled') ?? false;

    // Preload to reduce latency
    await _navPlayer.setSourceAsset('sounds/nav_blip.wav');
    await _navPlayer.setPlayerMode(PlayerMode.lowLatency);

    await _actionPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _alertPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _uiSoundsEnabled = prefs.getBool('ui_sounds_enabled') ?? false;
  }

  Future<void> playNavBlip() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _navPlayer.stop();
      await _navPlayer.play(AssetSource('sounds/nav_blip.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playButtonTap() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/button_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playRunStart() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/run_start.wav'));
    } catch (_) {}
  }

  Future<void> playPauseResume() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/pause_resume.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playRunFinish() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/run_finish.wav'));
    } catch (_) {}
  }

  Future<void> playError() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/error.wav'));
    } catch (_) {}
  }

  Future<void> playSuccess() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/pr_new.wav'));
    } catch (_) {}
  }

  Future<void> playPrNew() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/pr_new.wav'));
    } catch (_) {}
  }

  Future<void> playStreakFanfare() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/streak_fanfare.wav'));
    } catch (_) {}
  }
}

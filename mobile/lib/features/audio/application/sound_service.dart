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

  Future<void> playNavHome() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _navPlayer.stop();
      await _navPlayer.play(AssetSource('sounds/nav_home.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playNavRecord() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _navPlayer.stop();
      await _navPlayer.play(AssetSource('sounds/nav_record.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playNavYou() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _navPlayer.stop();
      await _navPlayer.play(AssetSource('sounds/nav_you.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playSwitchRun() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/switch_run.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playSwitchWalk() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/switch_walk.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playPaceUp() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/pace_up.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playPaceDown() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/pace_down.wav'), mode: PlayerMode.lowLatency);
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

  Future<void> playSettingsTap() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/settings_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playActivityTap() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/activity_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playToggleSwitch() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/toggle_switch.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playThemeLight() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/theme_light.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playThemeDark() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/theme_dark.wav'), mode: PlayerMode.lowLatency);
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

  Future<void> playRunDiscard() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/run_discard.wav'));
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

  Future<void> playTabBestEfforts() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/tab_best_efforts.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playTabAllTime() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/tab_all_time.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playFabAddRun() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/fab_add_run.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playMicStart() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/mic_start.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playChatBeep() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/chat_beep.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  // ── You screen tab sounds ─────────────────────────────────────────────────

  Future<void> playTabActivities() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/tab_activities.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playTabRecords() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/tab_records.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playTabProgress() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/tab_progress.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playRacePredictorTap() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/race_predictor_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playActivitiesCardTap() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/activities_card_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playWeekCardTap() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/week_card_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playWeeklyReportsTap() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/weekly_reports_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playCalendarDayTap() async {
    if (_uiSoundsEnabled == null) await _init();
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _actionPlayer.stop();
      await _actionPlayer.play(AssetSource('sounds/calendar_day_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> playSystemBack() async {
    if (_uiSoundsEnabled == null) {
      await _init();
    }
    if (!(_uiSoundsEnabled ?? false)) return;
    try {
      await _navPlayer.stop();
      await _navPlayer.play(AssetSource('sounds/system_back.wav'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }
}

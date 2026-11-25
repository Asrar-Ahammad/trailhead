import 'package:audioplayers/audioplayers.dart';

import '../domain/audio_repository_ui_sounds.dart';

enum _SoundChannel { nav, action, alert }

class AudioUiSoundService {
  static const _sounds = {
    AudioCue.navHome: (_SoundChannel.nav, 'nav_home.wav'),
    AudioCue.navRecord: (_SoundChannel.nav, 'nav_record.wav'),
    AudioCue.navYou: (_SoundChannel.nav, 'nav_you.wav'),
    AudioCue.switchRun: (_SoundChannel.action, 'switch_run.wav'),
    AudioCue.switchWalk: (_SoundChannel.action, 'switch_walk.wav'),
    AudioCue.paceUp: (_SoundChannel.action, 'pace_up.wav'),
    AudioCue.paceDown: (_SoundChannel.action, 'pace_down.wav'),
    AudioCue.buttonTap: (_SoundChannel.action, 'button_tap.wav'),
    AudioCue.settingsTap: (_SoundChannel.action, 'settings_tap.wav'),
    AudioCue.activityTap: (_SoundChannel.action, 'activity_tap.wav'),
    AudioCue.toggleSwitch: (_SoundChannel.action, 'toggle_switch.wav'),
    AudioCue.themeLight: (_SoundChannel.action, 'theme_light.wav'),
    AudioCue.themeDark: (_SoundChannel.action, 'theme_dark.wav'),
    AudioCue.runStart: (_SoundChannel.alert, 'run_start.wav'),
    AudioCue.pauseResume: (_SoundChannel.action, 'pause_resume.wav'),
    AudioCue.runFinish: (_SoundChannel.alert, 'run_finish.wav'),
    AudioCue.runDiscard: (_SoundChannel.alert, 'run_discard.wav'),
    AudioCue.error: (_SoundChannel.alert, 'error.wav'),
    AudioCue.prNew: (_SoundChannel.alert, 'pr_new.wav'),
    AudioCue.streakFanfare: (_SoundChannel.alert, 'streak_fanfare.wav'),
    AudioCue.tabBestEfforts: (_SoundChannel.action, 'tab_best_efforts.wav'),
    AudioCue.tabAllTime: (_SoundChannel.action, 'tab_all_time.wav'),
    AudioCue.fabAddRun: (_SoundChannel.action, 'fab_add_run.wav'),
    AudioCue.micStart: (_SoundChannel.action, 'mic_start.wav'),
    AudioCue.chatBeep: (_SoundChannel.action, 'chat_beep.wav'),
    AudioCue.tabActivities: (_SoundChannel.action, 'tab_activities.wav'),
    AudioCue.tabRecords: (_SoundChannel.action, 'tab_records.wav'),
    AudioCue.tabProgress: (_SoundChannel.action, 'tab_progress.wav'),
    AudioCue.racePredictorTap: (_SoundChannel.action, 'race_predictor_tap.wav'),
    AudioCue.activitiesCardTap: (
      _SoundChannel.action,
      'activities_card_tap.wav',
    ),
    AudioCue.weekCardTap: (_SoundChannel.action, 'week_card_tap.wav'),
    AudioCue.weeklyReportsTap: (_SoundChannel.action, 'weekly_reports_tap.wav'),
    AudioCue.calendarDayTap: (_SoundChannel.action, 'calendar_day_tap.wav'),
    AudioCue.systemBack: (_SoundChannel.nav, 'system_back.wav'),
  };

  final _players = <_SoundChannel, AudioPlayer>{};
  final _pending = <_SoundChannel, Future<void>>{};
  bool _disposed = false;

  Future<void> play(AudioCue cue) {
    if (_disposed) return Future<void>.value();
    final (channel, asset) = _sounds[cue]!;
    final previous = _pending[channel] ?? Future<void>.value();
    final next = previous.then((_) => _play(channel, asset));
    _pending[channel] = next;
    return next;
  }

  Future<void> _play(_SoundChannel channel, String asset) async {
    if (_disposed) return;
    try {
      final player = _players.putIfAbsent(channel, AudioPlayer.new);
      await player.stop();
      await player.play(
        AssetSource('sounds/$asset'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // UI feedback should not interrupt the action that triggered it.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await Future.wait(_pending.values);
    await Future.wait(_players.values.map((player) => player.dispose()));
  }
}

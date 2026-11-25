import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/audio/domain/audio_repository_ui_sounds.dart';
import '../../../features/audio/domain/audio_use_case_play_ui_sound.dart';

class AudioCubit extends Cubit<bool> {
  AudioCubit(this._repository, this._play) : super(_repository.isEnabled);

  final AudioRepository _repository;
  final PlayUiSound _play;
  bool _saving = false;

  Future<void> setEnabled(bool enabled) async {
    if (_saving || state == enabled) return;
    _saving = true;
    try {
      if (!await _repository.setEnabled(enabled)) {
        throw StateError('Could not save the UI sound preference.');
      }
      if (isClosed) return;
      emit(enabled);
      if (enabled) await playToggleSwitch();
    } finally {
      _saving = false;
    }
  }

  void reloadPreference() {
    if (!isClosed) emit(_repository.isEnabled);
  }

  Future<void> playNavHome() => _play(AudioCue.navHome, enabled: state);
  Future<void> playNavRecord() => _play(AudioCue.navRecord, enabled: state);
  Future<void> playNavYou() => _play(AudioCue.navYou, enabled: state);
  Future<void> playSwitchRun() => _play(AudioCue.switchRun, enabled: state);
  Future<void> playSwitchWalk() => _play(AudioCue.switchWalk, enabled: state);
  Future<void> playPaceUp() => _play(AudioCue.paceUp, enabled: state);
  Future<void> playPaceDown() => _play(AudioCue.paceDown, enabled: state);
  Future<void> playButtonTap() => _play(AudioCue.buttonTap, enabled: state);
  Future<void> playSettingsTap() => _play(AudioCue.settingsTap, enabled: state);
  Future<void> playActivityTap() => _play(AudioCue.activityTap, enabled: state);
  Future<void> playToggleSwitch() =>
      _play(AudioCue.toggleSwitch, enabled: state);
  Future<void> playThemeLight() => _play(AudioCue.themeLight, enabled: state);
  Future<void> playThemeDark() => _play(AudioCue.themeDark, enabled: state);
  Future<void> playRunStart() => _play(AudioCue.runStart, enabled: state);
  Future<void> playPauseResume() => _play(AudioCue.pauseResume, enabled: state);
  Future<void> playRunFinish() => _play(AudioCue.runFinish, enabled: state);
  Future<void> playRunDiscard() => _play(AudioCue.runDiscard, enabled: state);
  Future<void> playError() => _play(AudioCue.error, enabled: state);
  Future<void> playPrNew() => _play(AudioCue.prNew, enabled: state);
  Future<void> playStreakFanfare() =>
      _play(AudioCue.streakFanfare, enabled: state);
  Future<void> playTabBestEfforts() =>
      _play(AudioCue.tabBestEfforts, enabled: state);
  Future<void> playTabAllTime() => _play(AudioCue.tabAllTime, enabled: state);
  Future<void> playFabAddRun() => _play(AudioCue.fabAddRun, enabled: state);
  Future<void> playMicStart() => _play(AudioCue.micStart, enabled: state);
  Future<void> playChatBeep() => _play(AudioCue.chatBeep, enabled: state);
  Future<void> playTabActivities() =>
      _play(AudioCue.tabActivities, enabled: state);
  Future<void> playTabRecords() => _play(AudioCue.tabRecords, enabled: state);
  Future<void> playTabProgress() => _play(AudioCue.tabProgress, enabled: state);
  Future<void> playRacePredictorTap() =>
      _play(AudioCue.racePredictorTap, enabled: state);
  Future<void> playActivitiesCardTap() =>
      _play(AudioCue.activitiesCardTap, enabled: state);
  Future<void> playWeekCardTap() => _play(AudioCue.weekCardTap, enabled: state);
  Future<void> playWeeklyReportsTap() =>
      _play(AudioCue.weeklyReportsTap, enabled: state);
  Future<void> playCalendarDayTap() =>
      _play(AudioCue.calendarDayTap, enabled: state);
  Future<void> playSystemBack() => _play(AudioCue.systemBack, enabled: state);
  Future<void> playSuccess() => playPrNew();
}

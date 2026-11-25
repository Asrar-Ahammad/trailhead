enum AudioCue {
  navHome,
  navRecord,
  navYou,
  switchRun,
  switchWalk,
  paceUp,
  paceDown,
  buttonTap,
  settingsTap,
  activityTap,
  toggleSwitch,
  themeLight,
  themeDark,
  runStart,
  pauseResume,
  runFinish,
  runDiscard,
  error,
  prNew,
  streakFanfare,
  tabBestEfforts,
  tabAllTime,
  fabAddRun,
  micStart,
  chatBeep,
  tabActivities,
  tabRecords,
  tabProgress,
  racePredictorTap,
  activitiesCardTap,
  weekCardTap,
  weeklyReportsTap,
  calendarDayTap,
  systemBack,
}

abstract interface class AudioRepository {
  bool get isEnabled;
  Future<bool> setEnabled(bool enabled);
  Future<void> play(AudioCue cue);
}

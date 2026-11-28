enum ProfileSetting {
  name,
  birthDate,
  gender,
  weight,
  restDays,
  audioCues,
  cueFrequency,
}

typedef ProfileSettings = ({
  String? name,
  DateTime? birthDate,
  String? gender,
  double? weight,
  int restDays,
  DateTime? lastRestDaysUpdate,
  bool audioCues,
  double cueFrequency,
});

abstract interface class ProfileSettingsRepository {
  ProfileSettings read();
  Future<void> write(
    ProfileSetting setting,
    Object? value, {
    DateTime? updatedAt,
  });
}

bool canEditRestDays(DateTime? lastUpdate, DateTime now) =>
    lastUpdate == null ||
    lastUpdate.year != now.year ||
    lastUpdate.month != now.month;

int ageOnDate(DateTime birthday, DateTime now) {
  final birthdayPassed =
      now.month > birthday.month ||
      (now.month == birthday.month && now.day >= birthday.day);
  return now.year - birthday.year - (birthdayPassed ? 0 : 1);
}

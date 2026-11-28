import 'profile_repository_settings.dart';

class UpdateProfileSettings {
  UpdateProfileSettings(
    this.repository, {
    DateTime Function()? clock,
    required this.notifyCueFrequency,
  }) : clock = clock ?? DateTime.now;
  final ProfileSettingsRepository repository;
  final DateTime Function() clock;
  final void Function(double) notifyCueFrequency;

  Future<void> call(ProfileSetting setting, Object? input) async {
    final now = clock();
    switch (setting) {
      case ProfileSetting.restDays:
        if (!canEditRestDays(repository.read().lastRestDaysUpdate, now)) {
          throw const FormatException(
            'Rest days can only be updated once per month.',
          );
        }
        final days = int.tryParse(input as String);
        if (days == null || days < 0 || days > 31) {
          throw const FormatException('Enter a number from 0 to 31.');
        }
        await repository.write(setting, days, updatedAt: now);
      case ProfileSetting.weight:
        final String? text = (input as String?)?.trim();
        final weight = text == null || text.isEmpty
            ? null
            : double.tryParse(text);
        if (text != null &&
            text.isNotEmpty &&
            (weight == null || !weight.isFinite || weight <= 0)) {
          throw const FormatException('Enter a valid body weight.');
        }
        await repository.write(setting, weight);
      case ProfileSetting.name:
        await repository.write(setting, (input as String).trim());
      case ProfileSetting.cueFrequency:
        final value = input as double;
        await repository.write(setting, value);
        notifyCueFrequency(value);
      case ProfileSetting.birthDate:
      case ProfileSetting.gender:
      case ProfileSetting.audioCues:
        await repository.write(setting, input);
    }
  }
}

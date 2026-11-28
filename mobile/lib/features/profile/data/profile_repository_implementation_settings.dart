import 'package:shared_preferences/shared_preferences.dart';
import '../domain/profile_repository_settings.dart';

class ProfileSettingsPreferences implements ProfileSettingsRepository {
  ProfileSettingsPreferences(this.preferences);
  final SharedPreferences preferences;

  @override
  ProfileSettings read() {
    final frequency = preferences.getDouble('audio_cue_frequency');
    return (
      name: preferences.getString('user_name'),
      birthDate: DateTime.tryParse(preferences.getString('user_dob') ?? ''),
      gender: preferences.getString('user_gender'),
      weight: preferences.getDouble('user_weight_kg'),
      restDays: preferences.getInt('rest_days_limit') ?? 0,
      lastRestDaysUpdate: DateTime.tryParse(
        preferences.getString('last_rest_days_update') ?? '',
      ),
      audioCues: preferences.getBool('audio_cues_enabled') ?? true,
      cueFrequency: frequency == 0.5 ? 0.5 : 1.0,
    );
  }

  @override
  Future<void> write(
    ProfileSetting setting,
    Object? value, {
    DateTime? updatedAt,
  }) async {
    final saved = await switch (setting) {
      ProfileSetting.name => preferences.setString(
        'user_name',
        value as String,
      ),
      ProfileSetting.birthDate => preferences.setString(
        'user_dob',
        (value as DateTime).toIso8601String(),
      ),
      ProfileSetting.gender => preferences.setString(
        'user_gender',
        value as String,
      ),
      ProfileSetting.weight =>
        value == null
            ? preferences.remove('user_weight_kg')
            : preferences.setDouble('user_weight_kg', value as double),
      ProfileSetting.audioCues => preferences.setBool(
        'audio_cues_enabled',
        value as bool,
      ),
      ProfileSetting.cueFrequency => preferences.setDouble(
        'audio_cue_frequency',
        value as double,
      ),
      ProfileSetting.restDays => _saveRestDays(value as int, updatedAt!),
    };
    if (!saved) throw StateError('Could not save profile settings.');
  }

  Future<bool> _saveRestDays(int days, DateTime updatedAt) async {
    final previousDays = preferences.getInt('rest_days_limit');
    final previousDate = preferences.getString('last_rest_days_update');
    try {
      if (await preferences.setInt('rest_days_limit', days) &&
          await preferences.setString(
            'last_rest_days_update',
            updatedAt.toIso8601String(),
          )) {
        return true;
      }
    } catch (_) {
      // Restore both entries if either write fails.
    }
    if (previousDays == null) {
      await preferences.remove('rest_days_limit');
    } else {
      await preferences.setInt('rest_days_limit', previousDays);
    }
    if (previousDate == null) {
      await preferences.remove('last_rest_days_update');
    } else {
      await preferences.setString('last_rest_days_update', previousDate);
    }
    return false;
  }
}

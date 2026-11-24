import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingCubit extends Cubit<bool> {
  OnboardingCubit({required SharedPreferences preferences, required bool completed})
    : _preferences = preferences,
      super(completed);

  final SharedPreferences _preferences;

  Future<void> completeOnboarding() async {
    emit(true);
    await _preferences.setBool('seen_onboarding', true);
  }

  Future<void> resetOnboarding() async {
    emit(false);
    await _preferences.setBool('seen_onboarding', false);
  }
}

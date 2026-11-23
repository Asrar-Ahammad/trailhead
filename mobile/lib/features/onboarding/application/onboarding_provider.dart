import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialOnboardingProvider = Provider<bool>((ref) => false);

final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final initial = ref.watch(initialOnboardingProvider);
  return OnboardingNotifier(initial);
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(super.initial);

  Future<void> completeOnboarding() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }

  Future<void> resetOnboarding() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', false);
  }
}

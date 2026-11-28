import 'package:shared_preferences/shared_preferences.dart';
import '../domain/onboarding_repository_completion.dart';

class OnboardingCompletionPreferences
    implements OnboardingCompletionRepository {
  OnboardingCompletionPreferences(this.preferences);
  final SharedPreferences preferences;
  static const _key = 'seen_onboarding';
  @override
  bool get completed => preferences.getBool(_key) ?? false;
  @override
  Future<void> save(bool completed) async {
    if (!await preferences.setBool(_key, completed)) {
      throw StateError('Could not save onboarding completion.');
    }
  }
}

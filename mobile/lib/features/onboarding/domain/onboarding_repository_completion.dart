abstract interface class OnboardingCompletionRepository {
  bool get completed;
  Future<void> save(bool completed);
}

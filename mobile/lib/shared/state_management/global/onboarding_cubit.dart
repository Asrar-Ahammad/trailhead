import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/onboarding/domain/onboarding_repository_completion.dart';

class OnboardingCubit extends Cubit<bool> {
  OnboardingCubit(this.repository) : super(repository.completed);
  final OnboardingCompletionRepository repository;

  Future<void> completeOnboarding() => _setCompleted(true);
  Future<void> resetOnboarding() => _setCompleted(false);

  Future<void> _setCompleted(bool completed) async {
    await repository.save(completed);
    emit(completed);
  }
}

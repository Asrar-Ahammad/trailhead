import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/onboarding_use_case_request_permissions.dart';

typedef CreateOnboardingBloc = OnboardingBloc Function();

enum OnboardingAction { requestPermissions, finish }

enum OnboardingStatus {
  idle,
  requesting,
  granted,
  denied,
  saving,
  finished,
  saveFailed,
}

class OnboardingBloc extends Bloc<OnboardingAction, OnboardingStatus> {
  OnboardingBloc(this.permissions, this.complete)
    : super(OnboardingStatus.idle) {
    on<OnboardingAction>((action, emit) async {
      if (state == OnboardingStatus.saving ||
          state == OnboardingStatus.finished)
        return;
      if (action == OnboardingAction.finish) {
        emit(OnboardingStatus.saving);
        try {
          await complete();
          emit(OnboardingStatus.finished);
        } catch (_) {
          emit(OnboardingStatus.saveFailed);
        }
        return;
      }
      if (state == OnboardingStatus.requesting) return;
      emit(OnboardingStatus.requesting);
      var granted = false;
      try {
        granted = await permissions();
      } catch (_) {
        // The user can retry or finish the tour without permissions.
      }
      if (state == OnboardingStatus.requesting) {
        emit(granted ? OnboardingStatus.granted : OnboardingStatus.denied);
      }
    });
  }

  final RequestOnboardingPermissions permissions;
  final Future<void> Function() complete;
}

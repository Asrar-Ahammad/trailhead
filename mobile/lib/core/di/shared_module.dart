import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/audio/data/audio_repository_implementation_ui_sounds.dart';
import '../../features/audio/data/audio_service_ui_sounds.dart';
import '../../features/audio/domain/audio_repository_ui_sounds.dart';
import '../../features/audio/domain/audio_use_case_play_ui_sound.dart';
import '../../features/haptics/data/haptics_repository_implementation_feedback.dart';
import '../../features/haptics/data/haptics_service_feedback.dart';
import '../../features/haptics/domain/haptics_repository_feedback.dart';
import '../../features/haptics/domain/haptics_use_case_play_feedback.dart';
import '../../features/ai/data/ai_repository_implementation_configuration.dart';
import '../../features/ai/data/ai_repository_implementation_provider_reply.dart';
import '../../features/ai/data/ai_service_provider_reply.dart';
import '../../features/ai/domain/ai_repository_configuration.dart';
import '../../features/ai/domain/ai_repository_provider_reply.dart';
import '../../features/ai/state_management/ai_bloc_check_connection.dart';
import '../../shared/state_management/global/ai_config_cubit.dart';
import '../../shared/state_management/global/audio_cubit_ui_sounds.dart';
import '../../shared/state_management/global/distance_unit_cubit.dart';
import '../../shared/state_management/global/haptics_cubit_feedback.dart';
import '../../shared/state_management/global/navigation_cubit_main_tab.dart';
import '../../shared/state_management/global/onboarding_cubit.dart';
import '../../shared/state_management/global/theme_mode_cubit.dart';

class SharedModule {
  static void register({
    required GetIt getIt,
    required ThemeMode initialThemeMode,
    required bool onboardingCompleted,
  }) {
    _registerAudio(getIt);
    _registerHaptics(getIt);

    getIt.registerLazySingleton<ThemeModeCubit>(
      () => ThemeModeCubit(preferences: getIt(), initialMode: initialThemeMode),
    );
    getIt.registerLazySingleton<OnboardingCubit>(
      () =>
          OnboardingCubit(preferences: getIt(), completed: onboardingCompleted),
    );
    getIt.registerLazySingleton<DistanceUnitCubit>(DistanceUnitCubit.new);
    getIt.registerLazySingleton<NavigationCubit>(NavigationCubit.new);
    _registerAi(getIt);
  }

  static void _registerAi(GetIt getIt) {
    getIt.registerLazySingleton<AiConfigurationRepository>(
      () => AiConfigurationRepositoryImplementation(getIt()),
    );
    getIt.registerLazySingleton<AiProviderReplyService>(AiProviderReplyService.new);
    getIt.registerLazySingleton<AiReplyRepository>(
      () => AiReplyRepositoryImplementation(getIt()),
    );
    getIt.registerLazySingleton<AiConfigCubit>(() => AiConfigCubit(getIt()));
    getIt.registerFactory<AiConnectionBloc>(() => AiConnectionBloc(getIt()));
  }

  static void _registerAudio(GetIt getIt) {
    getIt.registerLazySingleton<AudioUiSoundService>(
      AudioUiSoundService.new,
      dispose: (service) => service.dispose(),
    );
    getIt.registerLazySingleton<AudioRepository>(
      () => AudioRepositoryImplementation(getIt(), getIt()),
    );
    getIt.registerLazySingleton<PlayUiSound>(() => PlayUiSound(getIt()));
    getIt.registerLazySingleton<AudioCubit>(
      () => AudioCubit(getIt(), getIt()),
      dispose: (cubit) => cubit.close(),
    );
  }

  static void _registerHaptics(GetIt getIt) {
    getIt.registerLazySingleton<HapticsFeedbackService>(
      HapticsFeedbackService.new,
    );
    getIt.registerLazySingleton<HapticsRepository>(
      () => HapticsRepositoryImplementation(getIt(), getIt()),
    );
    getIt.registerLazySingleton<PlayHapticFeedback>(
      () => PlayHapticFeedback(getIt()),
    );
    getIt.registerLazySingleton<HapticsCubit>(
      () => HapticsCubit(getIt(), getIt()),
    );
  }
}

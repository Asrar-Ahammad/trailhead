import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/audio/application/sound_service.dart';
import '../../features/haptics/application/haptics_service.dart';
import '../../features/ai/domain/ai_config.dart';
import '../../shared/state_management/global/ai_config_cubit.dart';
import '../../shared/state_management/global/distance_unit_cubit.dart';
import '../../shared/state_management/global/navigation_cubit.dart';
import '../../shared/state_management/global/onboarding_cubit.dart';
import '../../shared/state_management/global/theme_mode_cubit.dart';

class SharedModule {
  static void register({
    required GetIt getIt,
    required ThemeMode initialThemeMode,
    required bool onboardingCompleted,
    required AiConfig initialAiConfig,
  }) {
    getIt.registerLazySingleton<SoundService>(SoundService.new);
    getIt.registerLazySingleton<HapticsService>(HapticsService.new);

    getIt.registerLazySingleton<ThemeModeCubit>(
      () => ThemeModeCubit(
        preferences: getIt(),
        initialMode: initialThemeMode,
      ),
    );
    getIt.registerLazySingleton<OnboardingCubit>(
      () => OnboardingCubit(
        preferences: getIt(),
        completed: onboardingCompleted,
      ),
    );
    getIt.registerLazySingleton<DistanceUnitCubit>(DistanceUnitCubit.new);
    getIt.registerLazySingleton<NavigationCubit>(NavigationCubit.new);
    getIt.registerLazySingleton<AiConfigCubit>(
      () => AiConfigCubit(
        preferences: getIt(),
        initial: initialAiConfig,
      ),
    );
  }
}

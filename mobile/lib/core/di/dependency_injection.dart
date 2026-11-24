import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai/domain/ai_config.dart';
import 'core_module.dart';
import 'feature_module.dart';
import 'shared_module.dart';

final GetIt getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> initialize({
    required Isar isar,
    required SharedPreferences preferences,
    required ThemeMode initialThemeMode,
    required bool onboardingCompleted,
  }) async {
    await CoreModule.register(
      getIt: getIt,
      isar: isar,
      preferences: preferences,
    );

    final initialAiConfig = AiConfig(
      provider: preferences.getString('ai_provider') ?? 'openai',
      model: preferences.getString('ai_model') ?? 'gpt-5',
      apiKey: preferences.getString('ai_api_key') ?? '',
    );

    SharedModule.register(
      getIt: getIt,
      initialThemeMode: initialThemeMode,
      onboardingCompleted: onboardingCompleted,
      initialAiConfig: initialAiConfig,
    );
    FeatureModule.register(getIt: getIt);
  }
}

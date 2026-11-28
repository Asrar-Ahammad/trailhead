import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core_module.dart';
import 'feature_module.dart';
import 'shared_module.dart';

final GetIt getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> initialize({
    required Isar isar,
    required SharedPreferences preferences,
    required ThemeMode initialThemeMode,
  }) async {
    await CoreModule.register(
      getIt: getIt,
      isar: isar,
      preferences: preferences,
    );

    SharedModule.register(
      getIt: getIt,
      initialThemeMode: initialThemeMode,
    );
    FeatureModule.register(getIt: getIt);
  }
}

import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoreModule {
  static Future<void> register({
    required GetIt getIt,
    required Isar isar,
    required SharedPreferences preferences,
  }) async {
    getIt.registerSingleton<Isar>(isar);
    getIt.registerSingleton<SharedPreferences>(preferences);
  }
}

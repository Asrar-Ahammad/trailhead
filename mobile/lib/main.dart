import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/run_tracking/data/models/run_isar.dart';
import 'features/run_tracking/data/models/run_point_isar.dart';
import 'features/run_tracking/presentation/permission_gate_screen.dart';
import 'features/auth/presentation/auth_wrapper.dart';
import 'features/sync/application/sync_service.dart';
import 'features/sync/data/api_client.dart';
import 'features/sync/data/models/sync_job_isar.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_themes.dart';

late Isar isarInstance;

/// Riverpod provider for persisted theme mode.
/// Reads/writes 'themeMode' from SharedPreferences.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [RunIsarSchema, RunPointIsarSchema, SyncJobIsarSchema],
        directory: dir.path,
      );

      final apiClient = ApiClient();
      final syncService = SyncService(isar: isar, apiClient: apiClient);

      final success = await syncService.runSyncLoop();
      await isar.close();
      
      return success;
    } catch (e) {
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // Initialize Workmanager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  isarInstance = await Isar.open(
    [RunIsarSchema, RunPointIsarSchema, SyncJobIsarSchema],
    directory: dir.path,
  );

  runApp(
    const ProviderScope(
      child: TrailheadApp(),
    ),
  );
}

class TrailheadApp extends ConsumerWidget {
  const TrailheadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                  (themeMode == ThemeMode.system && 
                   WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
                   
    final initTheme = isDark ? AppThemes.darkTheme : AppThemes.lightTheme;

    return WithForegroundTask(
      child: ThemeProvider(
        initTheme: initTheme,
        builder: (context, myTheme) {
          return MaterialApp(
            title: 'Trailhead',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: myTheme,
            darkTheme: AppThemes.darkTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

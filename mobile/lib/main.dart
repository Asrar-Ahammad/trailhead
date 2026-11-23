import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/run_tracking/data/models/run_isar.dart';
import 'features/run_tracking/data/models/run_point_isar.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'package:trailhead_mobile/features/shoes/data/models/shoe_isar.dart';
import 'features/run_tracking/data/models/daily_steps_isar.dart';
import 'features/stats/data/models/personal_record_isar.dart';
import 'features/stats/data/models/weekly_report_isar.dart';
import 'features/goals/data/models/goal_isar.dart';
import 'features/run_tracking/application/background_step_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'features/notifications/application/notification_service.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'shared/theme/app_themes.dart';
import 'features/audio/application/sound_service.dart';
import 'shared/navigation/sound_navigator_observer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/navigation/presentation/main_scaffold.dart';

late Isar isarInstance;

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final initial = ref.watch(initialThemeModeProvider);
  return ThemeModeNotifier(initial);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initial) : super(initial);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  isarInstance = await Isar.open(
    [
      RunIsarSchema,
      RunPointIsarSchema,
      ShoeIsarSchema,
      DailyStepsIsarSchema,
      PersonalRecordIsarSchema,
      WeeklyReportIsarSchema,
      GoalIsarSchema,
    ],
    directory: dir.path,
  );

  // Initialize Notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e, st) {
    debugPrint('Notification initialization error: $e\n$st');
  }

  // Start background step counter service
  try {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'trailhead_steps',
        channelName: 'Step Counter',
        channelDescription: 'Counts your steps in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // Update notification every 60s
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
      ),
    );

    // Only start if not already running (e.g. run tracker service is active)
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        FlutterForegroundTask.startService(
          notificationTitle: 'Trailhead',
          notificationText: '0 steps today',
          callback: backgroundStepCallback,
        );
      } else {
        debugPrint('Activity recognition permission not granted. Skipping background step counter.');
      }
    }
  } catch (e, st) {
    debugPrint('Background step counter init error: $e\n$st');
  }

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode');
  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedTheme == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  }

  final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialOnboardingProvider.overrideWithValue(seenOnboarding),
      ],
      child: const TrailheadApp(),
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
    final soundService = ref.read(soundServiceProvider);
    final hasSeenOnboarding = ref.watch(onboardingCompletedProvider);

    final Widget homeScreen = hasSeenOnboarding
        ? const MainScaffold()
        : const OnboardingScreen();

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
            home: homeScreen,
            navigatorObservers: [
              SoundNavigatorObserver(soundService: soundService),
            ],
          );
        },
      ),
    );
  }
}

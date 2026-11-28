import 'features/run_tracking/state_management/run_tracking_bloc_permissions.dart';
import 'features/history/state_management/history_bloc_activity_actions.dart';
import 'features/history/state_management/history_bloc_route_points.dart';
import 'features/stats/state_management/stats_bloc_edit_record.dart';
import 'features/stats/state_management/stats_bloc_weekly_reports.dart';
import 'features/you/state_management/you_bloc_activity_actions.dart';
import 'features/you/state_management/you_bloc_activity_period.dart';
import 'features/run_tracking/state_management/run_tracking_bloc_workout_actions.dart';
import 'features/run_tracking/state_management/run_tracking_bloc_post_run_summary.dart';
import 'shared/state_management/global/history_cubit_activities.dart';
import 'shared/state_management/global/stats_cubit_records.dart';
import 'shared/state_management/global/run_tracking_cubit_route_map.dart';
import 'shared/state_management/global/shoes_cubit_inventory.dart';
import 'features/shoes/state_management/shoes_bloc_edit_gear.dart';
import 'features/shoes/state_management/shoes_bloc_activity.dart';
import 'features/home/state_management/home_bloc_dashboard.dart';
import 'features/weather/state_management/weather_bloc_pacing.dart';
import 'features/onboarding/state_management/onboarding_bloc_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/state_management/global/audio_cubit_ui_sounds.dart';
import 'features/run_tracking/data/models/run_isar.dart';
import 'features/run_tracking/data/models/run_point_isar.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'package:trailhead_mobile/features/shoes/data/models/shoe_isar.dart';
import 'features/run_tracking/data/models/daily_steps_isar.dart';
import 'features/stats/data/models/personal_record_isar.dart';
import 'features/stats/data/models/weekly_report_isar.dart';
import 'features/goals/data/models/goal_isar.dart';
import 'features/run_tracking/application/background_step_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'features/notifications/domain/notifications_repository_streak_nudge.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'shared/theme/app_themes.dart';
import 'shared/navigation/sound_navigator_observer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/navigation/presentation/navigation_scaffold_main_tabs.dart';
import 'core/di/dependency_injection.dart';
import 'shared/state_management/global/ai_config_cubit.dart';
import 'shared/state_management/global/distance_unit_cubit.dart';
import 'shared/state_management/global/haptics_cubit_feedback.dart';
import 'shared/state_management/global/navigation_cubit_main_tab.dart';
import 'shared/state_management/global/onboarding_cubit.dart';
import 'shared/state_management/global/theme_mode_cubit.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import 'shared/state_management/global/goals_cubit_targets.dart';
import 'features/goals/state_management/goals_bloc_progress.dart';
import 'features/goals/state_management/goals_bloc_edit_targets.dart';
import 'features/profile/state_management/profile_bloc_settings.dart';
import 'features/history/state_management/manual_entry_bloc.dart';
import 'features/data_management/state_management/data_management_bloc_backups.dart';
import 'features/chat/state_management/chat_bloc_coach_conversation.dart';
import 'features/ai/state_management/ai_bloc_check_connection.dart';
import 'features/predictions/state_management/predictions_bloc_race_predictions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    RunIsarSchema,
    RunPointIsarSchema,
    ShoeIsarSchema,
    DailyStepsIsarSchema,
    PersonalRecordIsarSchema,
    WeeklyReportIsarSchema,
    GoalIsarSchema,
  ], directory: dir.path);

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
        eventAction: ForegroundTaskEventAction.repeat(
          60000,
        ), // Update notification every 60s
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
        debugPrint(
          'Activity recognition permission not granted. Skipping background step counter.',
        );
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

  await DependencyInjection.initialize(
    isar: isar,
    preferences: prefs,
    initialThemeMode: initialThemeMode,
  );

  try {
    await getIt<NotificationsRepository>().initialize();
  } catch (error, stackTrace) {
    debugPrint('Notification initialization error: $error\n$stackTrace');
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeModeCubit>()),
        BlocProvider.value(value: getIt<OnboardingCubit>()),
        BlocProvider.value(value: getIt<DistanceUnitCubit>()),
        BlocProvider.value(value: getIt<HapticsCubit>()),
        BlocProvider.value(value: getIt<AudioCubit>()),
        BlocProvider.value(value: getIt<NavigationCubit>()),
        BlocProvider.value(value: getIt<AiConfigCubit>()),
        BlocProvider.value(value: getIt<RunTrackerCubit>()),
        BlocProvider.value(value: getIt<GoalsCubit>()),
        BlocProvider.value(value: getIt<ShoesCubit>()),
        BlocProvider.value(value: getIt<HistoryActivitiesCubit>()),
        BlocProvider.value(value: getIt<StatsRecordsCubit>()),
        BlocProvider.value(value: getIt<RunRouteMapCubit>()),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CreateManualEntryBloc>.value(
            value: () => getIt<ManualEntryBloc>(),
          ),
          RepositoryProvider<CreateYouBloc>.value(
            value: () => getIt<YouBloc>(),
          ),
          RepositoryProvider<CreateRecordEditor>.value(
            value: () => getIt<RecordEditorBloc>(),
          ),
          RepositoryProvider<CreateWeeklyReportsBloc>.value(
            value: () => getIt<WeeklyReportsBloc>(),
          ),
          RepositoryProvider<CreateDailyStepsBloc>.value(
            value: (date) => getIt<DailyStepsBloc>(param1: date),
          ),
          RepositoryProvider<CreatePeriodActivitiesBloc>.value(
            value: (start, end) =>
                getIt<PeriodActivitiesBloc>(param1: start, param2: end),
          ),
          RepositoryProvider<CreateHistoryRouteBloc>.value(
            value: (id) => getIt<HistoryRouteBloc>(param1: id),
          ),
          RepositoryProvider<CreateHistoryActionsBloc>.value(
            value: (run, route) =>
                getIt<HistoryActionsBloc>(param1: run, param2: route),
          ),
          RepositoryProvider<CreateRunPermissionsBloc>.value(
            value: () => getIt<RunPermissionsBloc>(),
          ),
          RepositoryProvider<CreateWorkoutActionsBloc>.value(
            value: () => getIt<WorkoutActionsBloc>(),
          ),
          RepositoryProvider<CreatePostRunSummaryBloc>.value(
            value: (run) => getIt<PostRunSummaryBloc>(param1: run),
          ),
          RepositoryProvider<CreateHomeBloc>.value(
            value: () => getIt<HomeBloc>(),
          ),
          RepositoryProvider<CreateShoeEditBloc>.value(
            value: () => getIt<ShoeEditBloc>(),
          ),
          RepositoryProvider<CreateShoeActivityBloc>.value(
            value: (id) => getIt<ShoeActivityBloc>(param1: id),
          ),
          RepositoryProvider<CreateProfileBloc>.value(
            value: () => getIt<ProfileBloc>(),
          ),
          RepositoryProvider<CreateEditGoalsBloc>.value(
            value: () => getIt<EditGoalsBloc>(),
          ),
          RepositoryProvider<CreateGoalProgressBloc>.value(
            value: (metrics) => getIt<GoalProgressBloc>(param1: metrics),
          ),
          RepositoryProvider<CreateWeatherBloc>.value(
            value: () => getIt<WeatherBloc>(),
          ),
          RepositoryProvider<CreateOnboardingBloc>.value(
            value: () => getIt<OnboardingBloc>(),
          ),
          RepositoryProvider<CreatePredictionsBloc>.value(
            value: () => getIt<PredictionsBloc>(),
          ),
          RepositoryProvider<CreateDataManagementBloc>.value(
            value: () => getIt<DataManagementBloc>(),
          ),
          RepositoryProvider<CreateChatBloc>.value(
            value: () => getIt<ChatBloc>(),
          ),
          RepositoryProvider<CreateAiConnectionBloc>.value(
            value: () => getIt<AiConnectionBloc>(),
          ),
        ],
        child: const TrailheadApp(),
      ),
    ),
  );
}

class TrailheadApp extends StatelessWidget {
  const TrailheadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeCubit>().state;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    final initTheme = isDark ? AppThemes.darkTheme : AppThemes.lightTheme;
    final audio = context.read<AudioCubit>();
    final hasSeenOnboarding = context.watch<OnboardingCubit>().state;

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
              SoundNavigatorObserver(playBackSound: audio.playSystemBack),
            ],
          );
        },
      ),
    );
  }
}

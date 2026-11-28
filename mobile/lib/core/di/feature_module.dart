import '../../features/run_tracking/data/run_tracking_repository_live_session.dart';
import '../../features/run_tracking/data/run_tracking_service_battery_settings.dart';
import '../../features/run_tracking/state_management/run_tracking_bloc_permissions.dart';
import '../../features/history/state_management/history_bloc_activity_actions.dart';
import '../../features/history/state_management/history_bloc_route_points.dart';
import '../../features/history/data/history_service_gpx_export.dart';
import '../../features/stats/state_management/stats_bloc_edit_record.dart';
import '../../features/stats/state_management/stats_bloc_weekly_reports.dart';
import '../../features/you/state_management/you_bloc_activity_actions.dart';
import '../../features/you/state_management/you_bloc_activity_period.dart';
import '../../features/run_tracking/data/run_tracking_repository_daily_steps.dart';
import '../../features/run_tracking/state_management/run_tracking_route_snapshots.dart';
import '../../features/run_tracking/state_management/run_tracking_bloc_workout_actions.dart';
import '../../features/run_tracking/state_management/run_tracking_bloc_post_run_summary.dart';
import '../../features/run_tracking/data/models/run_isar.dart';
import '../../shared/state_management/global/history_cubit_activities.dart';
import '../../shared/state_management/global/stats_cubit_records.dart';
import '../../shared/state_management/global/run_tracking_cubit_route_map.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import '../../shared/state_management/global/shoes_cubit_inventory.dart';
import '../../features/shoes/domain/shoes_repository_inventory.dart';
import '../../features/shoes/data/shoes_repository_implementation_inventory.dart';
import '../../features/shoes/domain/shoes_use_case_manage_gear.dart';
import '../../features/shoes/data/shoes_service_prepare_photo.dart';
import '../../features/shoes/data/shoes_repository_implementation_activity.dart';
import '../../features/shoes/state_management/shoes_bloc_activity.dart';
import '../../features/shoes/state_management/shoes_bloc_edit_gear.dart';
import '../../features/home/data/home_repository_implementation_dashboard.dart';
import '../../features/home/state_management/home_bloc_dashboard.dart';
import 'package:isar/isar.dart';
import '../../shared/state_management/global/ai_config_cubit.dart';
import '../../shared/state_management/global/audio_cubit_ui_sounds.dart';
import '../../shared/state_management/global/haptics_cubit_feedback.dart';

import '../../features/chat/data/chat_repository_implementation_coach_conversation.dart';
import '../../features/chat/data/chat_service_coach_reply.dart';
import '../../features/chat/domain/chat_repository_coach_conversation.dart';
import '../../features/chat/domain/chat_use_case_coach_conversation.dart';
import '../../features/chat/state_management/chat_bloc_coach_conversation.dart';
import '../../features/data_management/data/data_management_repository_implementation_backups.dart';
import '../../features/data_management/data/data_management_service_export.dart';
import '../../features/data_management/data/data_management_service_restore.dart';
import '../../features/data_management/domain/data_management_repository_backups.dart';
import '../../features/data_management/state_management/data_management_bloc_backups.dart';
import '../../features/goals/domain/goals_repository_targets.dart';
import '../../features/goals/domain/goals_use_case_calculate_progress.dart';
import '../../features/goals/data/goals_repository_implementation_targets.dart';
import '../../features/goals/data/goals_repository_implementation_progress.dart';
import '../../features/goals/state_management/goals_bloc_progress.dart';
import '../../features/goals/state_management/goals_bloc_edit_targets.dart';
import '../../features/profile/domain/profile_repository_settings.dart';
import '../../features/profile/domain/profile_use_case_update_settings.dart';
import '../../features/profile/data/profile_repository_implementation_settings.dart';
import '../../features/profile/state_management/profile_bloc_settings.dart';
import '../../shared/state_management/global/goals_cubit_targets.dart';
import '../../features/profile/data/profile_service_workout_settings.dart';
import '../../features/history/data/run_history_repository.dart';
import '../../features/history/data/repositories/ai_run_log_parser_repository.dart';
import '../../features/history/domain/repositories/run_log_parser_repository.dart';
import '../../features/history/domain/use_cases/parse_manual_run_log.dart';
import '../../features/history/domain/repositories/manual_run_repository.dart';
import '../../features/history/domain/use_cases/save_manual_run.dart';
import '../../features/history/state_management/manual_entry_bloc.dart';
import '../../features/notifications/data/notifications_repository_implementation_streak_nudge.dart';
import '../../features/notifications/data/notifications_service_streak_nudge.dart';
import '../../features/notifications/domain/notifications_repository_streak_nudge.dart';
import '../../features/predictions/data/predictions_repository_implementation_race_predictions.dart';
import '../../features/predictions/data/predictions_service_coach_advice.dart';
import '../../features/predictions/domain/predictions_repository_race_predictions.dart';
import '../../features/predictions/domain/predictions_use_case_load_race_predictions.dart';
import '../../features/predictions/state_management/predictions_bloc_race_predictions.dart';
import '../../features/run_tracking/application/ai_summary_service.dart';
import '../../features/run_tracking/application/nl_logging_service.dart';
import '../../features/run_tracking/application/run_analysis_service.dart';
import 'package:trailhead_mobile/shared/state_management/global/run_tracking_cubit_live_session.dart';
import '../../features/stats/application/ai_coach_service.dart';
import 'package:trailhead_mobile/features/stats/domain/stats_repository_personal_records.dart';
import '../../features/stats/data/stats_repository_implementation_personal_records.dart';
import '../../features/stats/data/weekly_report_service.dart';
import '../../features/weather/data/weather_repository_implementation_current_conditions.dart';
import '../../features/weather/domain/weather_repository_current_conditions.dart';
import '../../features/weather/data/weather_service_current_conditions.dart';
import '../../features/weather/state_management/weather_bloc_pacing.dart';

class FeatureModule {
  static void register({required GetIt getIt}) {
    getIt.registerLazySingleton<RunHistoryRepository>(
      () => RunHistoryRepository(getIt()),
    );
    getIt.registerLazySingleton<ManualRunRepository>(
      () => getIt<RunHistoryRepository>(),
    );
    getIt.registerLazySingleton<SaveManualRun>(
      () => SaveManualRun(getIt<ManualRunRepository>()),
    );
    _registerShoes(getIt);
    _registerHome(getIt);
    _registerHistory(getIt);
    _registerStats(getIt);
    _registerYou(getIt);
    _registerRunTracking(getIt);
    _registerWeather(getIt);
    getIt.registerLazySingleton<WeeklyReportService>(
      () => WeeklyReportService(getIt()),
    );
    _registerGoals(getIt);
    _registerProfile(getIt);
    getIt.registerLazySingleton<PersonalRecordsRepository>(
      () => PersonalRecordsIsar(getIt()),
    );
    getIt.registerLazySingleton<RunAnalysisService>(
      () => RunAnalysisService(
        isar: getIt<Isar>(),
        preferences: getIt(),
        aiConfigCubit: getIt(),
      ),
    );
    getIt.registerLazySingleton<AiSummaryService>(
      () => AiSummaryService(getIt()),
    );
    getIt.registerLazySingleton<AiCoachService>(
      () => AiCoachService(isar: getIt(), aiConfigCubit: getIt()),
    );
    _registerPredictions(getIt);
    _registerNotifications(getIt);
    _registerDataManagement(getIt);
    _registerChat(getIt);
    getIt.registerLazySingleton<NlLoggingService>(
      () => NlLoggingService(getIt()),
    );
    getIt.registerLazySingleton<RunLogParserRepository>(
      () => AiRunLogParserRepository(getIt<NlLoggingService>()),
    );
    getIt.registerLazySingleton<ParseManualRunLog>(
      () => ParseManualRunLog(getIt<RunLogParserRepository>()),
    );
    getIt.registerFactory<ManualEntryBloc>(
      () => ManualEntryBloc(getIt<ParseManualRunLog>(), getIt<SaveManualRun>()),
    );
    getIt.registerLazySingleton<LiveSessionRepository>(
      () => LiveSessionRepository(getIt()),
    );
    getIt.registerLazySingleton<RunTrackerCubit>(
      () => RunTrackerCubit(
        sessions: getIt(),
        preferences: getIt(),
        shoeService: getIt(),
        weatherRepository: getIt(),
        analysisService: getIt(),
        haptics: getIt(),
      ),
    );
  }

  static void _registerHistory(GetIt getIt) {
    getIt.registerLazySingleton<HistoryActivitiesCubit>(
      () => HistoryActivitiesCubit(
        getIt<RunHistoryRepository>().watchCompletedRuns,
      ),
      dispose: (cubit) => cubit.close(),
    );
    getIt.registerFactoryParam<HistoryRouteBloc, String?, void>(
      (id, _) =>
          HistoryRouteBloc(id, getIt<RunHistoryRepository>().getRunPoints),
    );
    getIt.registerLazySingleton<RunGpxExportService>(RunGpxExportService.new);
    getIt.registerFactoryParam<HistoryActionsBloc, RunIsar, HistoryRouteBloc>(
      (run, route) => HistoryActionsBloc(
        run,
        route,
        getIt(),
        getIt<RunHistoryRepository>().deleteRun,
      ),
    );
  }

  static void _registerStats(GetIt getIt) {
    getIt.registerLazySingleton<StatsRecordsCubit>(
      () => StatsRecordsCubit(getIt<PersonalRecordsRepository>().watchRecords),
      dispose: (cubit) => cubit.close(),
    );
    getIt.registerFactory<RecordEditorBloc>(() => RecordEditorBloc(getIt()));
    getIt.registerFactory<WeeklyReportsBloc>(
      () => WeeklyReportsBloc(getIt<WeeklyReportService>().loadReports),
    );
  }

  static void _registerYou(GetIt getIt) {
    getIt.registerFactory<YouBloc>(
      () => YouBloc(getIt<RunHistoryRepository>().deleteRuns),
    );
    getIt.registerLazySingleton<DailyStepsRepository>(
      () => DailyStepsRepository(getIt()),
    );
    getIt.registerFactoryParam<DailyStepsBloc, DateTime, void>(
      (date, _) => DailyStepsBloc(getIt<DailyStepsRepository>().watch(date)),
    );
    getIt.registerFactoryParam<PeriodActivitiesBloc, DateTime, DateTime>(
      (start, end) => PeriodActivitiesBloc(
        getIt<RunHistoryRepository>().watchPeriod(start, end),
      ),
    );
  }

  static void _registerRunTracking(GetIt getIt) {
    getIt.registerLazySingleton<RunRouteMapCubit>(() {
      final tracker = getIt<RunTrackerCubit>();
      final repository = getIt<LiveSessionRepository>();
      return RunRouteMapCubit(
        watchRunRouteSnapshots(
          initial: tracker.state,
          changes: tracker.stream,
          read: (state) async {
            final id = state.clientRunId;
            return id == null || state.status == 'idle'
                ? []
                : repository.readRoute(id);
          },
        ),
      );
    }, dispose: (cubit) => cubit.close());
    getIt.registerLazySingleton<RunBatterySettingsService>(
      RunBatterySettingsService.new,
    );
    getIt.registerFactory<RunPermissionsBloc>(() {
      final tracker = getIt<RunTrackerCubit>();
      return RunPermissionsBloc(
        foreground: tracker.requestForegroundPermission,
        background: tracker.requestBackgroundPermission,
        promptBatterySettings:
            getIt<RunBatterySettingsService>().promptIfNeeded,
      );
    });
    getIt.registerFactory<WorkoutActionsBloc>(
      () => WorkoutActionsBloc(
        getIt(),
        getIt<RunTrackerCubit>().stopRun,
        getIt<LiveSessionRepository>().readRoute,
        () => getIt<RunRouteMapCubit>().state.points,
      ),
    );
    getIt.registerFactoryParam<PostRunSummaryBloc, RunIsar, void>(
      (run, _) => PostRunSummaryBloc(
        run,
        summarize: getIt<AiSummaryService>().summarize,
        hasRecord: getIt<PersonalRecordsRepository>().hasBestEffortForRun,
      ),
    );
  }

  static void _registerHome(GetIt getIt) {
    getIt.registerLazySingleton<HomeDashboardRepository>(
      () => HomeDashboardRepository(getIt(), getIt(), getIt()),
    );
    getIt.registerFactory<HomeBloc>(() => HomeBloc(getIt()));
  }

  static void _registerShoes(GetIt getIt) {
    getIt.registerLazySingleton<ShoesRepository>(
      () => ShoesRepositoryImplementation(getIt()),
    );
    getIt.registerLazySingleton<ShoeActivityRepository>(
      () => ShoeActivityRepository(getIt()),
    );
    getIt.registerLazySingleton<ImageProcessingService>(
      ImageProcessingService.new,
      dispose: (service) => service.dispose(),
    );
    getIt.registerLazySingleton<ShoeService>(
      () => ShoeService(
        getIt(),
        newClientId: const Uuid().v4,
        preparePhoto: getIt<ImageProcessingService>().preparePhoto,
      ),
    );
    getIt.registerLazySingleton<ShoesCubit>(
      () => ShoesCubit(getIt()),
      dispose: (cubit) => cubit.close(),
    );
    getIt.registerFactory<ShoeEditBloc>(
      () => ShoeEditBloc(getIt(), getIt<RunTrackerCubit>().setSelectedShoe),
    );
    getIt.registerFactoryParam<ShoeActivityBloc, String?, void>(
      (id, _) => ShoeActivityBloc(getIt(), id),
    );
  }

  static void _registerGoals(GetIt getIt) {
    getIt.registerLazySingleton<GoalsRepository>(
      () => GoalsRepositoryImplementation(getIt(), getIt()),
    );
    getIt.registerLazySingleton<GoalProgressRepository>(
      () => IsarGoalProgressRepository(getIt()),
    );
    getIt.registerLazySingleton<GoalsCubit>(() => GoalsCubit(getIt()));
    getIt.registerFactoryParam<GoalProgressBloc, GoalMetrics, void>(
      (metrics, _) => GoalProgressBloc(getIt(), metrics),
    );
    getIt.registerFactory<EditGoalsBloc>(
      () => EditGoalsBloc(getIt<GoalsCubit>().saveGoals),
    );
  }

  static void _registerProfile(GetIt getIt) {
    getIt.registerLazySingleton<ProfileWorkoutSettingsService>(
      ProfileWorkoutSettingsService.new,
    );
    getIt.registerLazySingleton<ProfileSettingsRepository>(
      () => ProfileSettingsPreferences(getIt()),
    );
    getIt.registerLazySingleton<UpdateProfileSettings>(
      () => UpdateProfileSettings(
        getIt(),
        notifyCueFrequency:
            getIt<ProfileWorkoutSettingsService>().updateCueFrequency,
      ),
    );
    getIt.registerFactory<ProfileBloc>(() => ProfileBloc(getIt(), getIt()));
  }

  static void _registerWeather(GetIt getIt) {
    getIt.registerLazySingleton<WeatherService>(WeatherService.new);
    getIt.registerLazySingleton<WeatherRepository>(
      () => WeatherRepositoryImplementation(getIt()),
    );
    getIt.registerFactory<WeatherBloc>(() => WeatherBloc(getIt()));
  }

  static void _registerChat(GetIt getIt) {
    getIt.registerLazySingleton<ChatCoachReplyService>(
      () => ChatCoachReplyService(getIt()),
    );
    getIt.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImplementation(getIt(), getIt(), getIt()),
    );
    getIt.registerLazySingleton<ChatCoachConversation>(
      () => ChatCoachConversation(getIt()),
    );
    getIt.registerFactory<ChatBloc>(() => ChatBloc(getIt()));
  }

  static void _registerDataManagement(GetIt getIt) {
    getIt.registerLazySingleton<DataManagementRepository>(
      () => DataManagementRepositoryImplementation(
        DataExportService(getIt(), getIt()),
        DataImportService(getIt(), getIt()),
      ),
    );
    getIt.registerFactory<DataManagementBloc>(
      () => DataManagementBloc(
        getIt(),
        onPreferencesRestored: () {
          getIt<AiConfigCubit>().reloadPreference();
          getIt<AudioCubit>().reloadPreference();
          getIt<HapticsCubit>().reloadPreference();
          getIt<GoalsCubit>().reload();
        },
      ),
    );
  }

  static void _registerNotifications(GetIt getIt) {
    getIt.registerLazySingleton<NotificationsStreakNudgeService>(
      () => NotificationsStreakNudgeService(FlutterLocalNotificationsPlugin()),
    );
    getIt.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImplementation(getIt()),
    );
  }

  static void _registerPredictions(GetIt getIt) {
    getIt.registerLazySingleton<PredictionsCoachAdviceService>(
      () => PredictionsCoachAdviceService(getIt()),
    );
    getIt.registerLazySingleton<PredictionsRepository>(
      () => PredictionsRepositoryImplementation(
        getIt(),
        getIt(),
        getIt(),
        getIt(),
      ),
    );
    getIt.registerLazySingleton<LoadRacePredictions>(
      () => LoadRacePredictions(getIt()),
    );
    getIt.registerFactory<PredictionsBloc>(() => PredictionsBloc(getIt()));
  }
}

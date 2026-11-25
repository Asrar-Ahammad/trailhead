import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
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
import '../../features/goals/application/goals_cubit.dart';
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
import '../../features/run_tracking/application/run_tracker_controller.dart';
import '../../features/shoes/application/image_processing_service.dart';
import '../../features/shoes/application/shoe_service.dart';
import '../../features/shoes/data/shoe_repository.dart';
import '../../features/stats/application/ai_coach_service.dart';
import '../../features/stats/application/pr_engine.dart';
import '../../features/stats/data/weekly_report_service.dart';
import '../../features/weather/data/weather_repository.dart';

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
    getIt.registerLazySingleton<ShoeRepository>(() => ShoeRepository(getIt()));
    getIt.registerLazySingleton<ShoeService>(() => ShoeService(getIt()));
    getIt.registerLazySingleton<ImageProcessingService>(
      ImageProcessingService.new,
    );
    getIt.registerLazySingleton<WeatherRepository>(WeatherRepository.new);
    getIt.registerLazySingleton<WeeklyReportService>(
      () => WeeklyReportService(getIt()),
    );
    getIt.registerLazySingleton<GoalsCubit>(
      () => GoalsCubit(isar: getIt(), preferences: getIt()),
    );
    getIt.registerLazySingleton<PREngine>(() => PREngine(getIt()));
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
    getIt.registerLazySingleton<NlLoggingService>(() => NlLoggingService(getIt()));
    getIt.registerLazySingleton<RunLogParserRepository>(
      () => AiRunLogParserRepository(getIt<NlLoggingService>()),
    );
    getIt.registerLazySingleton<ParseManualRunLog>(
      () => ParseManualRunLog(getIt<RunLogParserRepository>()),
    );
    getIt.registerFactory<ManualEntryBloc>(
      () => ManualEntryBloc(
        getIt<ParseManualRunLog>(),
        getIt<SaveManualRun>(),
      ),
    );
    getIt.registerLazySingleton<RunTrackerCubit>(
      () => RunTrackerCubit(
        isar: getIt(),
        preferences: getIt(),
        shoeService: getIt(),
        weatherRepository: getIt(),
        analysisService: getIt(),
        haptics: getIt(),
      ),
    );
  }

  static void _registerChat(GetIt getIt) {
    getIt.registerLazySingleton<ChatCoachReplyService>(() => ChatCoachReplyService(getIt()));
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


import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';

import '../../features/chat/application/chat_service.dart';
import '../../features/goals/application/goals_cubit.dart';
import '../../features/history/data/run_history_repository.dart';
import '../../features/history/data/repositories/ai_run_log_parser_repository.dart';
import '../../features/history/domain/repositories/run_log_parser_repository.dart';
import '../../features/history/domain/use_cases/parse_manual_run_log.dart';
import '../../features/history/domain/repositories/manual_run_repository.dart';
import '../../features/history/domain/use_cases/save_manual_run.dart';
import '../../features/history/state_management/manual_entry_bloc.dart';
import '../../features/predictions/application/prediction_service.dart';
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
    getIt.registerLazySingleton<PredictionService>(
      () => PredictionService(
        isar: getIt(),
        preferences: getIt(),
        aiConfigCubit: getIt(),
      ),
    );
    getIt.registerLazySingleton<ChatService>(() => ChatService(getIt()));
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
      ),
    );
  }
}


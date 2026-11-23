import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/audio/application/sound_service.dart';
import '../../features/auth/application/auth_service.dart';
import '../../features/chat/application/chat_service.dart';
import '../../features/goals/application/goals_cubit.dart';
import '../../features/haptics/application/haptics_service.dart';
import '../../features/history/data/run_history_repository.dart';
import '../../features/history/application/run_points_cubit.dart';
import '../../features/goals/application/goal_progress_cubit.dart';
import '../../features/predictions/application/prediction_service.dart';
import '../../features/notifications/application/notification_service.dart';
import '../../features/run_tracking/application/nl_logging_service.dart';
import '../../features/run_tracking/application/run_tracker_controller.dart';
import '../../features/run_tracking/application/daily_steps_cubit.dart';
import '../../features/run_tracking/application/route_cubit.dart';
import '../../features/shoes/data/shoe_repository.dart';
import '../../features/shoes/application/shoe_service.dart';
import '../../features/shoes/application/shoe_cubits.dart';
import '../../features/sync/application/sync_service.dart';
import '../../features/sync/data/api_client.dart';
import '../../features/stats/application/pr_engine.dart';
import '../../features/stats/application/ai_coach_cubit.dart';
import '../../features/stats/data/weekly_report_api_client.dart';
import '../../features/stats/application/weekly_summary_cubit.dart';
import '../../features/weather/data/weather_repository.dart';
import '../../features/weather/application/weather_service.dart';
import '../../features/you/application/you_ui_cubit.dart';
import '../../features/you/application/activity_cubits.dart';

abstract class MutableCubit<StateType> extends Cubit<StateType> {
  MutableCubit(super.initialState);

  set state(StateType next) => emit(next);
}

enum AsyncStatus { loading, data, error }

class AsyncState<Value> {
  const AsyncState._(this.status, {this.value, this.error, this.stackTrace});
  const AsyncState.loading() : this._(AsyncStatus.loading);
  const AsyncState.data(Value value) : this._(AsyncStatus.data, value: value);
  const AsyncState.error(Object error, StackTrace stackTrace)
    : this._(AsyncStatus.error, error: error, stackTrace: stackTrace);

  final AsyncStatus status;
  final Value? value;
  final Object? error;
  final StackTrace? stackTrace;
  Value? get valueOrNull => value;
  bool get hasValue => status == AsyncStatus.data && value != null;

  Result when<Result>({
    required Result Function(Value value) data,
    required Result Function() loading,
    required Result Function(Object error, StackTrace stackTrace) error,
  }) => switch (status) {
    AsyncStatus.data => data(value as Value),
    AsyncStatus.loading => loading(),
    AsyncStatus.error => error(this.error!, stackTrace!),
  };

  Result maybeWhen<Result>({
    Result Function(Value value)? data,
    Result Function()? loading,
    Result Function(Object error, StackTrace stackTrace)? error,
    required Result Function() orElse,
  }) => switch (status) {
    AsyncStatus.data => data?.call(value as Value) ?? orElse(),
    AsyncStatus.loading => loading?.call() ?? orElse(),
    AsyncStatus.error => error?.call(this.error!, stackTrace!) ?? orElse(),
  };
}

/// App-wide state lives here so feature screens can access it through
/// `context.read<T>()` / `BlocBuilder<T, State>` without owning global state.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(ThemeMode initialMode) : super(initialMode);

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}

class DistanceUnitCubit extends Cubit<bool> {
  DistanceUnitCubit() : super(false);

  void setUseMiles(bool useMiles) {
    // Miles are intentionally disabled in the product at present.
    emit(false);
  }
}

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void selectTab(int index) {
    if (index >= 0 && index <= 2) emit(index);
  }
}

/// Modular registration point for application-wide Cubits.
class AppCubitProviders extends StatelessWidget {
  const AppCubitProviders({
    required this.initialThemeMode,
    required this.isar,
    required this.apiClient,
    required this.notificationService,
    required this.child,
    super.key,
  });

  final ThemeMode initialThemeMode;
  final Isar isar;
  final ApiClient apiClient;
  final NotificationService notificationService;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shoeService = ShoeService(
      ShoeRepository(isar),
      SyncService(isar: isar, apiClient: apiClient),
    );
    final weatherRepository = WeatherRepository();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<NotificationService>.value(
          value: notificationService,
        ),
        RepositoryProvider<SoundService>(create: (_) => SoundService()),
        RepositoryProvider<HapticsService>(create: (_) => HapticsService()),
        RepositoryProvider<AuthService>(create: (_) => AuthService()),
        RepositoryProvider<RunHistoryRepository>(
          create: (_) => RunHistoryRepository(isar, apiClient),
        ),
        RepositoryProvider<ShoeRepository>(create: (_) => ShoeRepository(isar)),
        RepositoryProvider<ShoeService>.value(value: shoeService),
        RepositoryProvider<WeatherRepository>.value(value: weatherRepository),
        RepositoryProvider<PREngine>(create: (_) => PREngine(apiClient)),
        RepositoryProvider<ChatService>(create: (_) => ChatService(apiClient)),
        RepositoryProvider<NlLoggingService>(
          create: (_) => NlLoggingService(apiClient),
        ),
        RepositoryProvider<PredictionService>(
          create: (_) => PredictionService(apiClient),
        ),
        RepositoryProvider<WeeklyReportApiClient>(
          create: (_) => WeeklyReportApiClient(apiClient.client),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(initialThemeMode)),
          BlocProvider(create: (_) => DistanceUnitCubit()),
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(create: (_) => YouUiCubit()),
          BlocProvider(
            create: (_) => CompletedRunsCubit(
              repository: RunHistoryRepository(isar, apiClient),
            ),
          ),
          BlocProvider(
            create: (_) => RunPointsCubit(
              repository: RunHistoryRepository(isar, apiClient),
            ),
          ),
          BlocProvider(
            create: (_) => PersonalRecordsCubit(engine: PREngine(apiClient)),
          ),
          BlocProvider(
            create: (_) => WeeklyRunsCubit(
              repository: RunHistoryRepository(isar, apiClient),
            ),
          ),
          BlocProvider(create: (_) => GoalsCubit(apiClient: apiClient)),
          BlocProvider(create: (_) => DailyStepsCubit(isar: isar)),
          BlocProvider(create: (_) => AllShoesCubit(service: shoeService)),
          BlocProvider(create: (_) => ActiveShoesCubit(service: shoeService)),
          BlocProvider(create: (_) => ShoeRunsCubit(isar: isar)),
          BlocProvider(
            create: (_) => WeatherPacingCubit(repository: weatherRepository),
          ),
          BlocProvider(
            create: (_) =>
                PredictionsCubit(service: PredictionService(apiClient)),
          ),
          BlocProvider(create: (_) => AiCoachCubit(apiClient: apiClient)),
          BlocProvider(
            create: (_) => WeeklyReportsCubit(
              client: WeeklyReportApiClient(apiClient.client),
            ),
          ),
          BlocProvider(
            create: (_) => WeeklySummaryCubit(
              repository: RunHistoryRepository(isar, apiClient),
            ),
          ),
          BlocProvider(
            create: (context) => GoalProgressCubit(
              isar: isar,
              goalsCubit: context.read<GoalsCubit>(),
            ),
          ),
          BlocProvider(
            create: (_) => RunTrackerCubit(
              shoeService: shoeService,
              weatherRepository: weatherRepository,
              apiClient: apiClient,
              notificationService: notificationService,
            ),
          ),
          BlocProvider(
            create: (context) => RouteCubit(
              isar: isar,
              runTracker: context.read<RunTrackerCubit>(),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}

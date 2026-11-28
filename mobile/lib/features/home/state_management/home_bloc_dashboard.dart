import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/state_management/async_value.dart';
import '../../stats/application/ai_coach_service.dart';
import '../data/home_repository_implementation_dashboard.dart';

typedef CreateHomeBloc = HomeBloc Function();

enum HomeLoad { week, coach, trend }

typedef HomeState = ({
  AsyncValue<HomeWeeklyData> week,
  AsyncValue<AiCoachData> coach,
  AsyncValue<String?> trend,
});

class HomeBloc extends Bloc<HomeLoad, HomeState> {
  HomeBloc(HomeDashboardRepository repository)
    : super((
        week: const AsyncValue.loading(),
        coach: const AsyncValue.loading(),
        trend: const AsyncValue.loading(),
      )) {
    on<HomeLoad>((event, emit) async {
      switch (event) {
        case HomeLoad.week:
          await emit.forEach(
            repository.watchWeek(),
            onData: (week) => (
              week: AsyncValue.data(week),
              coach: state.coach,
              trend: state.trend,
            ),
            onError: (error, trace) => (
              week: AsyncValue.error(error, trace),
              coach: state.coach,
              trend: state.trend,
            ),
          );
        case HomeLoad.coach:
          final coach = await _load(repository.loadCoach);
          emit((week: state.week, coach: coach, trend: state.trend));
        case HomeLoad.trend:
          final trend = await _load(repository.loadTrend);
          emit((week: state.week, coach: state.coach, trend: trend));
      }
    });
    for (final source in HomeLoad.values) {
      add(source);
    }
  }

  static Future<AsyncValue<T>> _load<T>(Future<T> Function() load) async {
    try {
      return AsyncValue.data(await load());
    } catch (error, trace) {
      return AsyncValue.error(error, trace);
    }
  }
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/weather/data/weather_response_model_current_conditions.dart';
import 'package:trailhead_mobile/features/weather/domain/weather_repository_current_conditions.dart';
import 'package:trailhead_mobile/features/weather/domain/weather_use_case_pacing.dart';
import 'package:trailhead_mobile/features/weather/state_management/weather_bloc_pacing.dart';
import 'package:trailhead_mobile/features/onboarding/domain/onboarding_use_case_request_permissions.dart';
import 'package:trailhead_mobile/features/onboarding/state_management/onboarding_bloc_setup.dart';

WeatherConditions conditions(double temperature, double wind) =>
    WeatherConditions(
      temperature: temperature,
      windSpeed: wind,
      code: 0,
      isDay: true,
      city: 'Local',
    );

class TestWeatherRepository implements WeatherRepository {
  TestWeatherRepository(this.result);
  final WeatherConditions? result;
  int calls = 0;
  @override
  Future<WeatherConditions?> getCurrentWeather() async {
    calls++;
    return result;
  }
}

void main() {
  test(
    'weather pacing preserves temperature and wind thresholds and miles display',
    () {
      for (final temp in [5.0, 20.0]) {
        final pace = WeatherPacing.forConditions(conditions(temp, 15));
        expect(pace.adjustmentSeconds, 0);
        expect(pace.displayPace(false), '5:30');
        expect(pace.displayPace(true), '8:51');
      }
      final warm = WeatherPacing.forConditions(conditions(25, 20));
      expect(warm.adjustmentSeconds, 35);
      expect(warm.advice, contains('headwinds'));
      expect(
        WeatherPacing.forConditions(conditions(1, 15)).adjustmentSeconds,
        12,
      );
    },
  );

  test('forecast maps alternate code and missing locality', () {
    final forecast = WeatherResponse({
      'temperature': 15,
      'windspeed': 9,
      'weather_code': 61,
      'is_day': 0,
    }, null).toConditions();
    expect(forecast.code, 61);
    expect(forecast.isDay, isFalse);
    expect(forecast.city, 'Unknown');
  });

  test(
    'dashboard loads one forecast and exposes unavailable location',
    () async {
      for (final result in [conditions(22, 12), null]) {
        final repository = TestWeatherRepository(result);
        final bloc = WeatherBloc(repository);
        addTearDown(bloc.close);
        final state = await bloc.stream.firstWhere((state) => !state.isLoading);
        expect(state.hasError, result == null);
        expect(
          state.valueOrNull?.adjustmentSeconds,
          result == null ? null : 10,
        );
        expect(repository.calls, 1);
      }
    },
  );

  test('foreground denial skips background request and allows retry', () async {
    var granted = false;
    var backgroundCalls = 0;
    final bloc = OnboardingBloc(
      RequestOnboardingPermissions(
        foreground: () async => granted,
        background: () async {
          backgroundCalls++;
          return true;
        },
      ),
      () async {},
    );
    addTearDown(bloc.close);
    final denied = bloc.stream.firstWhere((s) => s == OnboardingStatus.denied);
    bloc.add(OnboardingAction.requestPermissions);
    await denied;
    expect(backgroundCalls, 0);
    granted = true;
    final ready = bloc.stream.firstWhere((s) => s == OnboardingStatus.granted);
    bloc.add(OnboardingAction.requestPermissions);
    await ready;
    expect(backgroundCalls, 1);
  });

  test(
    'finishing during a permission prompt saves once and stays finished',
    () async {
      final foreground = Completer<bool>();
      var saves = 0;
      final bloc = OnboardingBloc(
        RequestOnboardingPermissions(
          foreground: () => foreground.future,
          background: () async => true,
        ),
        () async {
          saves++;
        },
      );
      final requesting = bloc.stream.firstWhere(
        (s) => s == OnboardingStatus.requesting,
      );
      bloc.add(OnboardingAction.requestPermissions);
      await requesting;
      final finished = bloc.stream.firstWhere(
        (s) => s == OnboardingStatus.finished,
      );
      bloc
        ..add(OnboardingAction.finish)
        ..add(OnboardingAction.finish);
      await finished;
      foreground.complete(false);
      await bloc.close();
      expect(saves, 1);
      expect(bloc.state, OnboardingStatus.finished);
    },
  );
}

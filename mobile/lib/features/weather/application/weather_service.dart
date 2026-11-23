import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/state/app_cubits.dart';
import '../data/weather_repository.dart';

class WeatherPacingCubit extends Cubit<AsyncState<Map<String, dynamic>>> {
  WeatherPacingCubit({required WeatherRepository repository})
      : _repository = repository,
        super(const AsyncState.loading()) {
    load();
  }

  final WeatherRepository _repository;

  Future<void> load() async {
    emit(const AsyncState.loading());
    try {
      final weatherData = await _repository.getCurrentWeather();
      if (weatherData == null) {
        throw Exception('Unable to fetch weather or location permission denied.');
      }
      final tempC = (weatherData['temperature'] as num).toDouble();
      final windSpeed = (weatherData['windspeed'] as num).toDouble();
      var paceAdjustmentSeconds = 0;
      var advice = 'Perfect running conditions!';
      if (tempC > 20) {
        paceAdjustmentSeconds += ((tempC - 20) * 5).round();
        advice = "It's warm out there. We've adjusted your target pace down to keep your heart rate in the right zone.";
      } else if (tempC < 5) {
        paceAdjustmentSeconds += ((5 - tempC) * 3).round();
        advice = "It's chilly. Take an extra 5 minutes to warm up your muscles.";
      }
      if (windSpeed > 15) {
        paceAdjustmentSeconds += ((windSpeed - 15) * 2).round();
        advice = advice == 'Perfect running conditions!'
            ? "It's quite windy. Expect some resistance and adjust your effort accordingly."
            : '$advice Also, watch out for headwinds.';
      }

      final adjustedPaceS = 330 + paceAdjustmentSeconds;
      final adjustedPace = '${adjustedPaceS ~/ 60}:${(adjustedPaceS % 60).toString().padLeft(2, '0')} / km';
      emit(AsyncState.data({
        'temperature': tempC,
        'windSpeed': windSpeed,
        'adjustmentSeconds': paceAdjustmentSeconds,
        'adjustedPace': adjustedPace,
        'weatherCode': weatherData['weathercode'],
        'advice': advice,
        'city': weatherData['city'] ?? 'Unknown',
      }));
    } catch (error, stackTrace) {
      emit(AsyncState.error(error, stackTrace));
    }
  }
}

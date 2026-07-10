import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/weather_repository.dart';

final weatherRepositoryProvider = Provider((ref) => WeatherRepository());

final weatherPacingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(weatherRepositoryProvider);
  final weatherData = await repo.getCurrentWeather();
  
  if (weatherData == null) {
    throw Exception('Unable to fetch weather or location permission denied.');
  }

  // weatherData contains: temperature (C), windspeed (km/h), weathercode
  final double tempC = (weatherData['temperature'] as num).toDouble();
  final double windSpeed = (weatherData['windspeed'] as num).toDouble();
  
  // Calculate pace adjustment
  // Heat slows you down (rule of thumb: ~5 secs per degree over 20C)
  // Wind slows you down (rough estimate: ~2 secs per km/h over 15km/h)
  int paceAdjustmentSeconds = 0;
  String advice = "Perfect running conditions!";
  
  if (tempC > 20) {
    paceAdjustmentSeconds += ((tempC - 20) * 5).round();
    advice = "It's warm out there. We've adjusted your target pace down to keep your heart rate in the right zone.";
  } else if (tempC < 5) {
    paceAdjustmentSeconds += ((5 - tempC) * 3).round();
    advice = "It's chilly. Take an extra 5 minutes to warm up your muscles.";
  }
  
  if (windSpeed > 15) {
    paceAdjustmentSeconds += ((windSpeed - 15) * 2).round();
    advice = advice == "Perfect running conditions!" 
        ? "It's quite windy. Expect some resistance and adjust your effort accordingly." 
        : advice + " Also, watch out for headwinds.";
  }

  // Baseline average pace for "Moderate" effort (could be fetched from history, hardcoded to 5:30/km for now)
  final basePaceS = 330;
  final adjustedPaceS = basePaceS + paceAdjustmentSeconds;
  
  final minutes = adjustedPaceS ~/ 60;
  final seconds = adjustedPaceS % 60;
  final adjustedPaceStr = '$minutes:${seconds.toString().padLeft(2, '0')} / km';

  return {
    'temperature': tempC,
    'windSpeed': windSpeed,
    'adjustmentSeconds': paceAdjustmentSeconds,
    'adjustedPace': adjustedPaceStr,
    'weatherCode': weatherData['weathercode'],
    'advice': advice,
    'city': weatherData['city'] ?? 'Unknown',
  };
});

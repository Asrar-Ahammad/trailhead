import 'weather_repository_current_conditions.dart';

class WeatherPacing {
  const WeatherPacing(this.conditions, this.adjustmentSeconds, this.advice);
  final WeatherConditions conditions;
  final int adjustmentSeconds;
  final String advice;

  int get adjustedPaceSeconds => 330 + adjustmentSeconds;
  String displayPace(bool useMiles) {
    final seconds = useMiles
        ? (adjustedPaceSeconds * 1.60934).round()
        : adjustedPaceSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  factory WeatherPacing.forConditions(WeatherConditions conditions) {
    final temperature = conditions.temperature;
    final wind = conditions.windSpeed;
    var adjustment = 0;
    var advice = 'Perfect running conditions!';
    if (temperature > 20) {
      adjustment = ((temperature - 20) * 5).round();
      advice =
          "It's warm out there. We've adjusted your target pace down to keep your heart rate in the right zone.";
    } else if (temperature < 5) {
      adjustment = ((5 - temperature) * 3).round();
      advice = "It's chilly. Take an extra 5 minutes to warm up your muscles.";
    }
    if (wind > 15) {
      adjustment += ((wind - 15) * 2).round();
      advice = temperature < 5 || temperature > 20
          ? '$advice Also, watch out for headwinds.'
          : "It's quite windy. Expect some resistance and adjust your effort accordingly.";
    }
    return WeatherPacing(conditions, adjustment, advice);
  }
}

import '../domain/weather_repository_current_conditions.dart';

class WeatherResponse {
  const WeatherResponse(this.current, this.city);
  final Map<String, dynamic> current;
  final String? city;

  WeatherConditions toConditions() => WeatherConditions(
    temperature: (current['temperature'] as num).toDouble(),
    windSpeed: (current['windspeed'] as num).toDouble(),
    code:
        ((current['weathercode'] ?? current['weather_code']) as num?)
            ?.toInt() ??
        0,
    isDay: (current['is_day'] ?? 1) == 1,
    city: city ?? 'Unknown',
  );
}

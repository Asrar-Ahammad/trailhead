class WeatherConditions {
  const WeatherConditions({
    required this.temperature,
    required this.windSpeed,
    required this.code,
    required this.isDay,
    required this.city,
  });
  final double temperature;
  final double windSpeed;
  final int code;
  final bool isDay;
  final String city;
}

abstract interface class WeatherRepository {
  Future<WeatherConditions?> getCurrentWeather();
}

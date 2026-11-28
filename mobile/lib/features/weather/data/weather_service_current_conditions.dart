import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'weather_request_model_current_conditions.dart';
import 'weather_response_model_current_conditions.dart';

class WeatherService {
  Future<WeatherResponse> fetch(WeatherRequest request) =>
      compute(_fetch, request);

  static Future<WeatherResponse> _fetch(WeatherRequest request) async {
    final client = Dio();
    try {
      final forecast = await client.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {...request.coordinates, 'current_weather': true},
      );
      String? city;
      try {
        final location = await client.get<Map<String, dynamic>>(
          'https://api.bigdatacloud.net/data/reverse-geocode-client',
          queryParameters: {...request.coordinates, 'localityLanguage': 'en'},
        );
        city =
            location.data?['city'] ??
            location.data?['locality'] ??
            'Unknown City';
      } on Exception {
        // The forecast remains usable without a city.
      }
      return WeatherResponse(
        forecast.data!['current_weather'] as Map<String, dynamic>,
        city,
      );
    } finally {
      client.close();
    }
  }
}

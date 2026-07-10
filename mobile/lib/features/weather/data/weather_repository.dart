import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class WeatherRepository {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> getCurrentWeather() async {
    try {
      // Ensure we have permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      
      final weatherResponse = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'current_weather': true,
        }
      );

      // Free reverse geocoding to get city name
      String? cityName;
      try {
        final geoResponse = await _dio.get(
          'https://api.bigdatacloud.net/data/reverse-geocode-client',
          queryParameters: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'localityLanguage': 'en',
          }
        );
        cityName = geoResponse.data['city'] ?? geoResponse.data['locality'] ?? 'Unknown City';
      } catch (_) {}

      final data = weatherResponse.data['current_weather'] as Map<String, dynamic>;
      data['city'] = cityName;
      
      return data;
    } catch (e) {
      print('Failed to fetch weather: $e');
      return null;
    }
  }
}

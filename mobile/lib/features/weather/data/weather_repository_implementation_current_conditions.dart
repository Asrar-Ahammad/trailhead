import 'package:geolocator/geolocator.dart';
import '../domain/weather_repository_current_conditions.dart';
import 'weather_request_model_current_conditions.dart';
import 'weather_service_current_conditions.dart';

class WeatherRepositoryImplementation implements WeatherRepository {
  WeatherRepositoryImplementation(this.service);
  final WeatherService service;

  @override
  Future<WeatherConditions?> getCurrentWeather() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final response = await service.fetch(
        WeatherRequest(position.latitude, position.longitude),
      );
      return response.toConditions();
    } catch (_) {
      return null;
    }
  }
}

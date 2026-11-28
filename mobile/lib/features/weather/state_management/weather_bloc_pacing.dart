import '../../../shared/state_management/local/async_resource_bloc.dart';
import '../domain/weather_repository_current_conditions.dart';
import '../domain/weather_use_case_pacing.dart';

typedef CreateWeatherBloc = WeatherBloc Function();

class WeatherBloc extends AsyncResourceBloc<WeatherPacing> {
  WeatherBloc(WeatherRepository repository) {
    add(
      LoadResource(() async {
        final conditions = await repository.getCurrentWeather();
        if (conditions == null) throw StateError('Weather unavailable');
        return WeatherPacing.forConditions(conditions);
      }),
    );
  }
}

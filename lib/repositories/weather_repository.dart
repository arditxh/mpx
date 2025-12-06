import 'package:mpx/models/weather_failure.dart';
import 'package:mpx/services/weather_service.dart';

/// Repository boundary between the ViewModel and remote weather data.
abstract class WeatherRepository {
  Future<WeatherResult<WeatherBundle>> getWeatherBundle({
    required double latitude,
    required double longitude,
  });
}

class HttpWeatherRepository implements WeatherRepository {
  HttpWeatherRepository({WeatherService? service})
      : _service = service ?? WeatherService();

  final WeatherService _service;

  @override
  Future<WeatherResult<WeatherBundle>> getWeatherBundle({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final bundle = await _service.fetchWeather(latitude, longitude);
      return WeatherResult.success(bundle);
    } on WeatherServiceException catch (e) {
      return WeatherResult.failure(
        WeatherFailure(e.reason, message: e.message),
      );
    } catch (_) {
      return const WeatherResult.failure(
        WeatherFailure(WeatherFailureReason.unknown),
      );
    }
  }
}

import 'package:geolocator/geolocator.dart';

import 'package:mpx/models/dailyModel.dart';
import 'package:mpx/models/hourlyModel.dart';
import 'package:mpx/models/weather.dart';
import 'package:mpx/services/location_service.dart';
import 'package:mpx/services/weather_service.dart';

// Shared fake weather bundle for tests.
final fakeWeatherBundle = WeatherBundle(
  current: Weather(temperature: 70, condition: 'Clear', code: 0),
  hourly: HourlyModel(
    times: const [],
    temperatures: const [],
    codes: const [],
    precipitationProbability: const [],
  ),
  daily: DailyModel(
    times: const [],
    tempMax: const [],
    tempMin: const [],
    codes: const [],
    precipitationProbabilityMax: const [],
  ),
);

class FakeWeatherService extends WeatherService {
  @override
  Future<WeatherBundle?> fetchWeather(double lat, double lon) async {
    return fakeWeatherBundle;
  }
}

class FakeLocationService extends LocationService {
  FakeLocationService({
    LocationResult? result,
    this.permissionStatus = LocationPermission.whileInUse,
  })
      : _result = result ??
            const LocationResult.failure(LocationFailureReason.unavailable);

  final LocationResult _result;
  final LocationPermission permissionStatus;

  @override
  Future<LocationResult> getCurrentPosition() async => _result;

  @override
  Future<LocationPermission> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermission> requestPermission() async => permissionStatus;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

Position buildFakePosition({
  double latitude = 10,
  double longitude = 20,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 1.0,
    altitude: 0.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    floor: 1,
  );
}

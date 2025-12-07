import 'package:geolocator/geolocator.dart';

import 'package:mpx/models/dailyModel.dart';
import 'package:mpx/models/hourlyModel.dart';
import 'package:mpx/models/settings.dart';
import 'package:mpx/models/weather.dart';
import 'package:mpx/models/weather_failure.dart';
import 'package:mpx/models/city.dart';
import 'package:mpx/repositories/city_repository.dart';
import 'package:mpx/repositories/settings_repository.dart';
import 'package:mpx/repositories/weather_repository.dart';
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

class FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherResult<WeatherBundle>> getWeatherBundle({
    required double latitude,
    required double longitude,
  }) async => WeatherResult.success(fakeWeatherBundle);
}

class FakeLocationService extends LocationService {
  FakeLocationService({
    LocationResult? result,
    this.permissionStatus = LocationPermission.whileInUse,
  }) : _result =
           result ??
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

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({Settings initial = const Settings()})
    : _settings = initial;

  Settings _settings;

  @override
  Future<Settings> load() async => _settings;

  @override
  Future<void> save(Settings settings) async {
    _settings = settings;
  }
}

class FakeCityRepository implements CityRepository {
  FakeCityRepository({List<City>? initial}) : _cities = List.of(initial ?? []);

  List<City> _cities;

  @override
  Future<List<City>> load() async => List.of(_cities);

  @override
  Future<void> save(List<City> cities) async {
    _cities = List.of(cities);
  }
}

Position buildFakePosition({double latitude = 10, double longitude = 20}) {
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

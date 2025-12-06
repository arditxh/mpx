import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/city.dart';
import '../models/weather_failure.dart';
import '../repositories/weather_repository.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class CityWeather {
  CityWeather({required this.city, required this.bundle});

  final City city;
  final WeatherBundle bundle;
}

class WeatherViewModel extends ChangeNotifier {
  // Allow injecting repository/services for testing; defaults to real implementations
  final WeatherRepository _repository;
  final GeocodingService _geocoding;
  final LocationService _location;

  WeatherViewModel({
    WeatherRepository? repository,
    GeocodingService? geocoding,
    LocationService? location,
  })  : _repository = repository ?? HttpWeatherRepository(),
        _geocoding = geocoding ?? GeocodingService(),
        _location = location ?? LocationService();


  final List<CityWeather> _cities = [];
  bool _loading = false;
  String? _error;
  int _selectedIndex = 0;
  LocationFailureReason? _lastLocationFailure;

  List<CityWeather> get cities => List.unmodifiable(_cities);
  bool get isLoading => _loading;
  String? get error => _error;
  int get selectedIndex => _selectedIndex;
  CityWeather? get selected =>
      _cities.isEmpty ? null : _cities[_selectedIndex.clamp(0, _cities.length - 1)];
  LocationFailureReason? get lastLocationFailure => _lastLocationFailure;
  bool get canRequestLocation =>
      _lastLocationFailure != LocationFailureReason.permissionPermanentlyDenied;

  Future<void> bootstrap() async {
    if (_loading) return;
    _setLoading(true);
    await ensureCurrentLocationCity(promptPermission: true);
    _setLoading(false);
  }

  Future<void> addCityByName(String name) async {
    _setLoading(true);
    try {
      final city = await _geocoding.searchCity(name);
      if (city == null) {
        _error = 'City not found';
      } else {
        await _addCity(city);
      }
    } catch (e) {
      _error = 'Failed to add city.';
    }
    _setLoading(false);
  }

  Future<void> addCityFromCoords(City city) async {
    _setLoading(true);
    try {
      await _addCity(city);
    } catch (e) {
      _error = 'Failed to add city.';
    }
    _setLoading(false);
  }

  Future<void> refreshCity(int index) async {
    if (index < 0 || index >= _cities.length) return;
    _setLoading(true, silent: true);
    try {
      var cityWeather = _cities[index];
      City targetCity = cityWeather.city;

      // For current location, refresh coordinates before fetching weather.
      if (targetCity.name == 'Current Location') {
        final posResult = await _location.getCurrentPosition();
        _lastLocationFailure = posResult.error;
        if (posResult.position != null) {
          targetCity = City(
            name: 'Current Location',
            latitude: posResult.position!.latitude,
            longitude: posResult.position!.longitude,
          );
        } else {
          _error = _locationErrorMessage(posResult.error);
          _setLoading(false, silent: true);
          notifyListeners();
          return;
        }
      }

      final result = await _repository.getWeatherBundle(
        latitude: targetCity.latitude,
        longitude: targetCity.longitude,
      );
      if (result.isSuccess && result.value != null) {
        final bundle = result.value!;
        _cities[index] = CityWeather(city: targetCity, bundle: bundle);
        _error = null;
        _lastLocationFailure = null;
      } else {
        _error = _weatherErrorMessage(targetCity.name, result.failure);
      }
    } catch (e) {
      _error = 'Failed to refresh ${_cities[index].city.name}';
    }
    _setLoading(false, silent: true);
    notifyListeners();
  }

  void selectCity(int index) {
    if (index < 0 || index >= _cities.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> ensureCurrentLocationCity({bool promptPermission = false}) async {
    if (promptPermission) {
      await _promptForPermission();
    }

    final locationResult = await _location.getCurrentPosition();
    _lastLocationFailure = locationResult.error;
    if (locationResult.position != null) {
      final city = City(
        name: 'Current Location',
        latitude: locationResult.position!.latitude,
        longitude: locationResult.position!.longitude,
      );
      final existingIndex =
          _cities.indexWhere((c) => c.city.name == 'Current Location');
      if (existingIndex >= 0) {
        await refreshCity(existingIndex);
      } else {
        await _addCity(city);
      }
      _lastLocationFailure = null;
      return;
    }

    if (_cities.isEmpty) {
      await _addCity(
        const City(name: 'Pittsburgh', latitude: 40.4406, longitude: -79.9959),
      );
      final message = _locationErrorMessage(locationResult.error);
      _error = '$message Showing Pittsburgh. Enable location and refresh.';
      notifyListeners();
    } else {
      _error = _locationErrorMessage(locationResult.error);
      notifyListeners();
    }
  }

  Future<void> requestLocationAccess() async {
    if (_loading) return;
    _setLoading(true);
    await _promptForPermission(force: true);
    await ensureCurrentLocationCity();
    _setLoading(false);
  }

  Future<void> openLocationSettings() async {
    await _location.openAppSettings();
  }

  Future<void> _addCity(City city) async {
    if (_cities.any((c) => c.city.name.toLowerCase() == city.name.toLowerCase())) {
      _error = 'City already added';
      return;
    }

    final result = await _repository.getWeatherBundle(
      latitude: city.latitude,
      longitude: city.longitude,
    );
    if (!result.isSuccess || result.value == null) {
      _error = _weatherErrorMessage(city.name, result.failure);
      return;
    }

    _cities.add(CityWeather(city: city, bundle: result.value!));
    _error = null;
    _selectedIndex = _cities.length - 1;
    notifyListeners();
  }

  Future<void> removeCity(int index) async {
    if (index < 0 || index >= _cities.length) return;
    _cities.removeAt(index);
    if (_selectedIndex >= _cities.length) {
      _selectedIndex = _cities.length - 1;
    }
    notifyListeners();
  }

  void _setLoading(bool value, {bool silent = false}) {
    _loading = value;
    if (!silent) {
      notifyListeners();
    }
  }

  String _weatherErrorMessage(String cityName, WeatherFailure? failure) {
    if (failure == null) return 'Weather data unavailable for $cityName';
    switch (failure.reason) {
      case WeatherFailureReason.network:
        return 'Network issue fetching $cityName. Check your connection.';
      case WeatherFailureReason.invalidResponse:
        return 'Unexpected response for $cityName weather. Please retry.';
      case WeatherFailureReason.parsing:
        return 'Could not read weather data for $cityName. Try again later.';
      case WeatherFailureReason.unknown:
      default:
        return 'Weather data unavailable for $cityName.';
    }
  }

  String _locationErrorMessage(LocationFailureReason? reason) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return 'Turn on location services to see local weather.';
      case LocationFailureReason.permissionDenied:
        return 'Location permission denied. Enable access and refresh.';
      case LocationFailureReason.permissionPermanentlyDenied:
        return 'Location permission denied permanently. Enable it in system settings.';
      case LocationFailureReason.timeout:
        return 'Timed out while getting your location. Pull to refresh to try again.';
      case LocationFailureReason.unavailable:
      default:
        return 'Location unavailable right now. Pull to refresh to retry.';
    }
  }

  Future<void> _promptForPermission({bool force = false}) async {
    var status = await _location.checkPermission();
    final needsRequest = force ||
        status == LocationPermission.denied ||
        status == LocationPermission.unableToDetermine;
    if (needsRequest) {
      status = await _location.requestPermission();
    }

    if (status == LocationPermission.denied) {
      _lastLocationFailure = LocationFailureReason.permissionDenied;
      _error = _locationErrorMessage(_lastLocationFailure);
    } else if (status == LocationPermission.deniedForever) {
      _lastLocationFailure = LocationFailureReason.permissionPermanentlyDenied;
      _error = _locationErrorMessage(_lastLocationFailure);
    }
  }
}

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/city.dart';
import '../models/weather_failure.dart';
import '../repositories/city_repository.dart';
import '../repositories/weather_repository.dart';
import '../l10n/app_localizations.dart';
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
  final CityRepository _cityRepository;

  WeatherViewModel({
    WeatherRepository? repository,
    GeocodingService? geocoding,
    LocationService? location,
    CityRepository? cityRepository,
    Locale? locale,
  }) : _repository = repository ?? HttpWeatherRepository(),
       _geocoding = geocoding ?? GeocodingService(),
       _location = location ?? LocationService(),
       _cityRepository = cityRepository ?? SharedPrefsCityRepository(),
       _locale = locale ?? const Locale('en');

  final List<CityWeather> _cities = [];
  bool _loading = false;
  String? _error;
  int _selectedIndex = 0;
  LocationFailureReason? _lastLocationFailure;
  Locale _locale;

  List<CityWeather> get cities => List.unmodifiable(_cities);
  bool get isLoading => _loading;
  String? get error => _error;
  int get selectedIndex => _selectedIndex;
  CityWeather? get selected => _cities.isEmpty
      ? null
      : _cities[_selectedIndex.clamp(0, _cities.length - 1)];
  LocationFailureReason? get lastLocationFailure => _lastLocationFailure;
  bool get canRequestLocation =>
      _lastLocationFailure != LocationFailureReason.permissionPermanentlyDenied;
  AppLocalizations get _strings {
    final match = AppLocalizations.supportedLocales.firstWhere(
      (l) => l.languageCode == _locale.languageCode,
      orElse: () => const Locale('en'),
    );
    return lookupAppLocalizations(match);
  }

  void updateLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
  }

  Future<void> bootstrap() async {
    if (_loading) return;
    _setLoading(true);
    await _loadSavedCities();
    await ensureCurrentLocationCity(promptPermission: true);
    _setLoading(false);
  }

  Future<void> _loadSavedCities() async {
    try {
      final saved = await _cityRepository.load();
      if (saved.isEmpty) return;

      var restoreFailed = false;
      for (final city in saved) {
        final result = await _repository.getWeatherBundle(
          latitude: city.latitude,
          longitude: city.longitude,
        );
        if (result.isSuccess && result.value != null) {
          _cities.add(CityWeather(city: city, bundle: result.value!));
        } else {
          restoreFailed = true;
        }
      }

      if (_cities.isNotEmpty) {
        _selectedIndex = 0;
      }
      if (restoreFailed) {
        _error = _strings.cityRestorePartial;
      }
    } catch (_) {
      _error ??= _strings.loadSavedCitiesFailed;
    }
    notifyListeners();
  }

  Future<void> addCityByName(String name) async {
    _setLoading(true);
    try {
      final city = await _geocoding.searchCity(name);
      if (city == null) {
        _error = _strings.cityNotFound;
      } else {
        await _addCity(city);
      }
    } catch (e) {
      _error = _strings.failedToAddCity;
    }
    _setLoading(false);
  }

  Future<void> addCityFromCoords(City city) async {
    _setLoading(true);
    try {
      await _addCity(city);
    } catch (e) {
      _error = _strings.failedToAddCity;
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
        await _persistCities();
      } else {
        _error = _weatherErrorMessage(targetCity.name, result.failure);
      }
    } catch (e) {
      final name = _cities[index].city.name;
      _error = _strings.failedToRefreshCity(name);
    }
    _setLoading(false, silent: true);
    notifyListeners();
  }

  void selectCity(int index) {
    if (index < 0 || index >= _cities.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> ensureCurrentLocationCity({
    bool promptPermission = false,
  }) async {
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
      final existingIndex = _cities.indexWhere(
        (c) => c.city.name == 'Current Location',
      );
      if (existingIndex >= 0) {
        await refreshCity(existingIndex);
      } else {
        await _addCity(city);
      }
      _lastLocationFailure = null;
      return;
    }

    if (_cities.isEmpty) {
      const fallbackCity = City(
        name: 'Pittsburgh',
        latitude: 40.4406,
        longitude: -79.9959,
      );
      await _addCity(fallbackCity);
      final message = _locationErrorMessage(locationResult.error);
      _error = _strings.locationFallbackMessage(fallbackCity.name, message);
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
    if (_cities.any(
      (c) => c.city.name.toLowerCase() == city.name.toLowerCase(),
    )) {
      _error = _strings.cityAlreadyAdded;
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
    await _persistCities();
    notifyListeners();
  }

  Future<void> removeCity(int index) async {
    if (index < 0 || index >= _cities.length) return;
    _cities.removeAt(index);
    if (_selectedIndex >= _cities.length) {
      _selectedIndex = _cities.isEmpty ? 0 : _cities.length - 1;
    }
    await _persistCities();
    notifyListeners();
  }

  Future<void> _persistCities() async {
    try {
      await _cityRepository.save(_cities.map((c) => c.city).toList());
    } catch (_) {
      // Ignore persistence failures to keep UI responsive.
    }
  }

  void _setLoading(bool value, {bool silent = false}) {
    _loading = value;
    if (!silent) {
      notifyListeners();
    }
  }

  String _weatherErrorMessage(String cityName, WeatherFailure? failure) {
    if (failure == null) return _strings.weatherUnavailable(cityName);
    switch (failure.reason) {
      case WeatherFailureReason.network:
        return _strings.networkIssueForCity(cityName);
      case WeatherFailureReason.invalidResponse:
        return _strings.unexpectedResponseForCity(cityName);
      case WeatherFailureReason.parsing:
        return _strings.parsingErrorForCity(cityName);
      case WeatherFailureReason.unknown:
      default:
        return _strings.weatherUnavailable(cityName);
    }
  }

  String _locationErrorMessage(LocationFailureReason? reason) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return _strings.locationServiceDisabled;
      case LocationFailureReason.permissionDenied:
        return _strings.locationPermissionDenied;
      case LocationFailureReason.permissionPermanentlyDenied:
        return _strings.locationPermissionPermanentlyDenied;
      case LocationFailureReason.timeout:
        return _strings.locationTimeout;
      case LocationFailureReason.unavailable:
      default:
        return _strings.locationUnavailable;
    }
  }

  Future<void> _promptForPermission({bool force = false}) async {
    var status = await _location.checkPermission();
    final needsRequest =
        force ||
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

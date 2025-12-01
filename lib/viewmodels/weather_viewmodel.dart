import 'package:flutter/foundation.dart';

import '../models/city.dart';
import '../models/dailyModel.dart';
import '../models/hourlyModel.dart';
import '../models/weather.dart';
import '../services/geocoding_service.dart';
import '../services/weather_service.dart';

class CityWeather {
  CityWeather({required this.city, required this.bundle});

  final City city;
  final WeatherBundle bundle;
}

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _service = WeatherService();
  final GeocodingService _geocoding = GeocodingService();

  final List<CityWeather> _cities = [];
  bool _loading = false;
  String? _error;
  int _selectedIndex = 0;

  List<CityWeather> get cities => List.unmodifiable(_cities);
  bool get isLoading => _loading;
  String? get error => _error;
  int get selectedIndex => _selectedIndex;
  CityWeather? get selected =>
      _cities.isEmpty ? null : _cities[_selectedIndex.clamp(0, _cities.length - 1)];

  Future<void> bootstrap() async {
    if (_cities.isNotEmpty) return;
    await addCityFromCoords(const City(name: 'Pittsburgh', latitude: 40.4406, longitude: -79.9959));
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
      final cityWeather = _cities[index];
      final bundle = await _service.fetchWeather(
        cityWeather.city.latitude,
        cityWeather.city.longitude,
      );
      if (bundle != null) {
        _cities[index] = CityWeather(city: cityWeather.city, bundle: bundle);
        _error = null;
      } else {
        _error = 'Weather data unavailable for ${cityWeather.city.name}';
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

  Future<void> _addCity(City city) async {
    if (_cities.any((c) => c.city.name.toLowerCase() == city.name.toLowerCase())) {
      _error = 'City already added';
      return;
    }

    final bundle = await _service.fetchWeather(city.latitude, city.longitude);
    if (bundle == null) {
      _error = 'Weather data unavailable for ${city.name}';
      return;
    }

    _cities.add(CityWeather(city: city, bundle: bundle));
    _error = null;
    _selectedIndex = _cities.length - 1;
    notifyListeners();
  }

  void _setLoading(bool value, {bool silent = false}) {
    _loading = value;
    if (!silent) {
      notifyListeners();
    }
  }
}

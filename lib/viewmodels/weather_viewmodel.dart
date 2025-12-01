import 'package:flutter/foundation.dart';

import '../models/dailyModel.dart';
import '../models/hourlyModel.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  Weather? _current;
  HourlyModel? _hourly;
  DailyModel? _daily;
  bool _loading = false;
  String? _error;

  Weather? get current => _current;
  HourlyModel? get hourly => _hourly;
  DailyModel? get daily => _daily;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetchWeather(double lat, double lon) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final bundle = await _service.fetchWeather(lat, lon);
      if (bundle == null) {
        _error = 'Weather data unavailable.';
        _current = null;
        _hourly = null;
        _daily = null;
      } else {
        _current = bundle.current;
        _hourly = bundle.hourly;
        _daily = bundle.daily;
      }
    } catch (e) {
      _error = 'Failed to load weather.';
      _current = null;
      _hourly = null;
      _daily = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/dailyModel.dart';
import '../models/hourlyModel.dart';
import '../models/weather_failure.dart';
import '../models/weather.dart';

class WeatherBundle {
  WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final Weather current;
  final HourlyModel hourly;
  final DailyModel daily;
}

class WeatherService {
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherBundle> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      '$_base?latitude=$lat&longitude=$lon&current_weather=true'
      '&hourly=temperature_2m,weathercode,precipitation_probability'
      '&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max'
      '&forecast_days=7'
      '&timezone=auto'
      '&temperature_unit=fahrenheit',
    );
    http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 10));
    } on TimeoutException catch (_) {
      throw WeatherServiceException(
        WeatherFailureReason.network,
        message: 'Request to weather service timed out.',
      );
    } catch (e) {
      throw WeatherServiceException(
        WeatherFailureReason.network,
        message: 'Network error: $e',
      );
    }

    if (response.statusCode != 200) {
      throw WeatherServiceException(
        WeatherFailureReason.invalidResponse,
        message: 'Weather API returned HTTP ${response.statusCode}.',
      );
    }

    try {
      // Offload parsing and Fahrenheit conversion to a background isolate.
      final bundle = await compute(_parseWeatherBundle, response.body);
      if (bundle == null) {
        throw WeatherServiceException(
          WeatherFailureReason.parsing,
          message: 'Received malformed weather data.',
        );
      }
      return bundle;
    } on WeatherServiceException {
      rethrow;
    } catch (_) {
      throw WeatherServiceException(
        WeatherFailureReason.parsing,
        message: 'Failed to parse weather data.',
      );
    }
  }
}

WeatherBundle? _parseWeatherBundle(String body) {
  final data = json.decode(body) as Map<String, dynamic>;
  final currentRaw = data['current_weather'] as Map<String, dynamic>?;
  final hourlyRaw = data['hourly'] as Map<String, dynamic>?;
  final dailyRaw = data['daily'] as Map<String, dynamic>?;
  final hourlyUnits = data['hourly_units'] as Map<String, dynamic>?;
  final currentUnits = data['current_weather_units'] as Map<String, dynamic>?;

  if (currentRaw == null || hourlyRaw == null || dailyRaw == null) {
    return null;
  }

  final isFahrenheit = hourlyUnits?['temperature_2m'] == '°F';

  Map<String, dynamic> convertCurrent(Map<String, dynamic> raw) {
    final unit = currentUnits?['temperature'] as String?;
    if (unit == '°F') return raw;
    final tempC = (raw['temperature'] ?? raw['temperature_2m'] ?? 0) as num;
    return {...raw, 'temperature': (tempC * 9 / 5) + 32};
  }

  Map<String, dynamic> convertHourly(Map<String, dynamic> raw) {
    if (isFahrenheit) return raw;
    final temps = (raw['temperature_2m'] as List<dynamic>)
        .map((t) => ((t as num) * 9 / 5) + 32)
        .toList();
    return {...raw, 'temperature_2m': temps};
  }

  Map<String, dynamic> convertDaily(Map<String, dynamic> raw) {
    if (isFahrenheit) return raw;
    List<double> convertList(String key) =>
        (raw[key] as List<dynamic>).map((t) => ((t as num) * 9 / 5) + 32).toList();
    return {
      ...raw,
      'temperature_2m_max': convertList('temperature_2m_max'),
      'temperature_2m_min': convertList('temperature_2m_min'),
    };
  }

  return WeatherBundle(
    current: Weather.fromJson(convertCurrent(currentRaw)),
    hourly: HourlyModel.fromJson({'hourly': convertHourly(hourlyRaw)}),
    daily: DailyModel.fromJson(convertDaily(dailyRaw)),
  );
}

class WeatherServiceException implements Exception {
  WeatherServiceException(this.reason, {this.message});

  final WeatherFailureReason reason;
  final String? message;

  @override
  String toString() => message ?? 'WeatherServiceException($reason)';
}

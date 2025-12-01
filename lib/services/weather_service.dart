import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/dailyModel.dart';
import '../models/hourlyModel.dart';
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

  Future<WeatherBundle?> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      '$_base?latitude=$lat&longitude=$lon&current_weather=true'
      '&hourly=temperature_2m&daily=temperature_2m_max,temperature_2m_min&timezone=auto'
      '&temperature_unit=fahrenheit',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      return null;
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final currentRaw = data['current_weather'] as Map<String, dynamic>?;
    final hourlyRaw = data['hourly'] as Map<String, dynamic>?;
    final dailyRaw = data['daily'] as Map<String, dynamic>?;

    if (currentRaw == null || hourlyRaw == null || dailyRaw == null) {
      return null;
    }

    return WeatherBundle(
      current: Weather.fromJson(currentRaw),
      hourly: HourlyModel.fromJson({'hourly': hourlyRaw}),
      daily: DailyModel.fromJson(dailyRaw),
    );
  }
}

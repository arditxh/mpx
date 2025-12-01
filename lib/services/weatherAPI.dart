import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currentModel.dart';
import '../models/dailyModel.dart';
import '../models/hourlyModel.dart';

class WeatherApi {
  final http.Client _client;
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  WeatherApi(this._client);

  Future<CurrentModel> getCurrentWeather({required double longitude, required double latitude}) async {
    final url = Uri.parse(
      '$_base?latitude=$latitude&longitude=$longitude&current=temperature_2m&timezone=America%2FNew_York',
    );
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch current weather: ${response.statusCode}');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final current = data['current'];
    return CurrentModel.fromJson(current);
  }

  Future<DailyModel> getDailyWeather({required double longitude, required double latitude}) async {
    final url = Uri.parse(
      '$_base?latitude=$latitude&longitude=$longitude'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=America%2FNew_York',
    );
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch daily weather: ${response.statusCode}');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final daily = data['daily'];
    return DailyModel.fromJson(daily);
  }

  Future<HourlyModel> getHourlyWeather({required double longitude, required double latitude}) async {
    final url = Uri.parse(
      '$_base?latitude=$latitude&longitude=$longitude'
      '&hourly=temperature_2m'
      '&timezone=America%2FNew_York',
    );
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch hourly weather: ${response.statusCode}');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final hourly = data['hourly'];
    return HourlyModel.fromJson({'hourly': hourly});
  }
}
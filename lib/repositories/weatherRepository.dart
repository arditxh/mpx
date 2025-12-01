import '../models/currentModel.dart';
import '../models/dailyModel.dart';
import '../models/hourlyModel.dart';
import '../services/WeatherAPI.dart';



class WeatherRepository {
  final WeatherApi api;
  WeatherRepository(this.api);

  Future<CurrentModel> getCurrentWeather({required double longitude, required double latitude}) =>
      api.getCurrentWeather(longitude: longitude, latitude: latitude);

  Future<DailyModel> getDailyWeather({required double longitude, required double latitude}) =>
      api.getDailyWeather(longitude: longitude, latitude: latitude);

  Future<HourlyModel> getHourlyWeather({required double longitude, required double latitude}) =>
      api.getHourlyWeather(longitude: longitude, latitude: latitude);
      
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:mpx/models/city.dart';
import 'package:mpx/models/weather.dart';
import 'package:mpx/models/hourlyModel.dart';
import 'package:mpx/models/dailyModel.dart';
import 'package:mpx/services/weather_service.dart';

// Fake WeatherBundle to avoid hitting real API
final fakeBundle = WeatherBundle(
  current: Weather(temperature: 70, condition: 'Clear', code: 0),
  hourly: HourlyModel(
    times: [],
    temperatures: [],
    codes: [],
    precipitationProbability: [],
  ),
  daily: DailyModel(
    times: [],
    tempMax: [],
    tempMin: [],
    codes: [],
    precipitationProbabilityMax: [],
  ),
);

// Fake WeatherService
class FakeWeatherService extends WeatherService {
  @override
  Future<WeatherBundle?> fetchWeather(double lat, double lon) async {
    return fakeBundle;
  }
}

void main() {
  test('addCityFromCoords adds a city successfully', () async {
    final vm = WeatherViewModel(service: FakeWeatherService());

    await vm.addCityFromCoords(
      const City(name: 'Testville', latitude: 10.0, longitude: 20.0),
    );

    expect(vm.cities.length, 1);
    expect(vm.cities.first.city.name, 'Testville');
  });

  test('selectCity updates the selected index', () {
    final vm = WeatherViewModel(service: FakeWeatherService());
    vm.selectCity(0); // no cities, should do nothing
    expect(vm.selectedIndex, 0);

    vm.selectCity(1); // still invalid
    expect(vm.selectedIndex, 0);
  });

  test('Cannot add duplicate city', () async {
    final vm = WeatherViewModel(service: FakeWeatherService());

    await vm.addCityFromCoords(
      const City(name: 'Pittsburgh', latitude: 40, longitude: -79),
    );
    await vm.addCityFromCoords(
      const City(name: 'Pittsburgh', latitude: 40, longitude: -79),
    );

    expect(vm.cities.length, 1);
    expect(vm.error, 'City already added');
  });
}

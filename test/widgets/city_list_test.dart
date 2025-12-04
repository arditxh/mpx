import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:mpx/models/city.dart';
import 'package:mpx/models/weather.dart';
import 'package:mpx/models/hourlyModel.dart';
import 'package:mpx/models/dailyModel.dart';
import 'package:provider/provider.dart';
import 'package:mpx/services/weather_service.dart';

// Fake WeatherBundle
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
  testWidgets('Shows a city when added', (tester) async {
    // Inject fake service through constructor
    final vm = WeatherViewModel(service: FakeWeatherService());

    // Add city using ViewModel method
    await vm.addCityFromCoords(
      const City(name: 'Pittsburgh', latitude: 40, longitude: -79),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pittsburgh'), findsOneWidget);
  });
}

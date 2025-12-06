import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:mpx/models/city.dart';
import 'package:mpx/services/location_service.dart';

import '../helpers/fakes.dart';

void main() {
  test('addCityFromCoords adds a city successfully', () async {
    final vm = WeatherViewModel(
      repository: FakeWeatherRepository(),
      location: FakeLocationService(
        result: LocationResult.success(buildFakePosition()),
      ),
    );

    await vm.addCityFromCoords(
      const City(name: 'Testville', latitude: 10.0, longitude: 20.0),
    );

    expect(vm.cities.length, 1);
    expect(vm.cities.first.city.name, 'Testville');
  });

  test('selectCity updates the selected index', () {
    final vm = WeatherViewModel(
      repository: FakeWeatherRepository(),
      location: FakeLocationService(
        result: LocationResult.success(buildFakePosition()),
      ),
    );
    vm.selectCity(0); // no cities, should do nothing
    expect(vm.selectedIndex, 0);

    vm.selectCity(1); // still invalid
    expect(vm.selectedIndex, 0);
  });

  test('Cannot add duplicate city', () async {
    final vm = WeatherViewModel(
      repository: FakeWeatherRepository(),
      location: FakeLocationService(
        result: LocationResult.success(buildFakePosition()),
      ),
    );

    await vm.addCityFromCoords(
      const City(name: 'Pittsburgh', latitude: 40, longitude: -79),
    );
    await vm.addCityFromCoords(
      const City(name: 'Pittsburgh', latitude: 40, longitude: -79),
    );

    expect(vm.cities.length, 1);
    expect(vm.error, 'City already added');
  });

  test('bootstrap uses current location when available', () async {
    final vm = WeatherViewModel(
      repository: FakeWeatherRepository(),
      location: FakeLocationService(
        result: LocationResult.success(
          buildFakePosition(latitude: 50, longitude: -120),
        ),
      ),
    );

    await vm.bootstrap();

    expect(vm.cities, isNotEmpty);
    expect(vm.cities.first.city.name, 'Current Location');
    expect(vm.error, isNull);
  });

  test('bootstrap falls back with message when location denied', () async {
    final vm = WeatherViewModel(
      repository: FakeWeatherRepository(),
      location: FakeLocationService(
        result: const LocationResult.failure(
          LocationFailureReason.permissionDenied,
        ),
      ),
    );

    await vm.bootstrap();

    expect(vm.cities.first.city.name, 'Pittsburgh');
    expect(vm.error, contains('permission'));
  });
}

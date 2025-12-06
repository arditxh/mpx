import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/services/location_service.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

class NoopBootstrapWeatherViewModel extends WeatherViewModel {
  NoopBootstrapWeatherViewModel({
    super.repository,
    super.geocoding,
    super.location,
  });

  @override
  Future<void> bootstrap() async {}
}

void main() {
  testWidgets('Shows empty state text when no cities added', (tester) async {
    final vm = NoopBootstrapWeatherViewModel(
      repository: FakeWeatherRepository(),
      location: FakeLocationService(
        result: const LocationResult.failure(
          LocationFailureReason.permissionDenied,
        ),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<WeatherViewModel>.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('No cities yet'), findsOneWidget);
  });
}

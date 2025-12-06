import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/services/location_service.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('HomeScreen shows app title', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WeatherViewModel(
          repository: FakeWeatherRepository(),
          location: FakeLocationService(
            result: LocationResult.success(buildFakePosition()),
          ),
        ),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Weather'), findsOneWidget);
  });
}

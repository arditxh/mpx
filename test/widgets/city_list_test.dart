import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/l10n/app_localizations.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/settings_viewmodel.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:mpx/models/city.dart';
import 'package:mpx/services/location_service.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('Shows a city when added', (tester) async {
    // Inject fake service through constructor
    final vm = WeatherViewModel(
      repository: FakeWeatherRepository(),
      cityRepository: FakeCityRepository(),
      location: FakeLocationService(
        result: const LocationResult.failure(
          LocationFailureReason.permissionDenied,
        ),
      ),
    );

    // Add city using ViewModel method
    await vm.addCityFromCoords(
      const City(name: 'Pittsburgh', latitude: 40, longitude: -79),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                SettingsViewModel(repository: FakeSettingsRepository()),
          ),
          ChangeNotifierProvider.value(value: vm),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pittsburgh'), findsOneWidget);
  });
}

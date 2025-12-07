import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/l10n/app_localizations.dart';
import 'package:mpx/services/location_service.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/settings_viewmodel.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('HomeScreen shows app title', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                SettingsViewModel(repository: FakeSettingsRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => WeatherViewModel(
              repository: FakeWeatherRepository(),
              cityRepository: FakeCityRepository(),
              location: FakeLocationService(
                result: LocationResult.success(buildFakePosition()),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('Weather App'), findsOneWidget);
  });
}

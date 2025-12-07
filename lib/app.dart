import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()..load()),
        ChangeNotifierProvider(create: (_) => WeatherViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          final lightTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          );
          final darkTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          );

          return MaterialApp(
            title: 'Weather',
            //locale: settings.locale, older version
            locale: settings.settings.languageCode.isEmpty
                ? null // use system language first
                : Locale(settings.settings.languageCode),
            localizationsDelegates: const [
              AppLocalizations.delegate, // Generated localization delegate
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            //supportedLocales: const [Locale('en')], older version
            supportedLocales: AppLocalizations.supportedLocales,
            
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settings.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

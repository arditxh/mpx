// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Weather App';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get useMetric => 'Use Metric Units';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get noData => 'No data available';

  @override
  String get currentWeather => 'Current Weather';

  @override
  String get dailyForecast => 'Daily Forecast';

  @override
  String get hourly => 'Hourly';

  @override
  String get addCity => 'Add a city';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get addRemoveCity => 'Add / Remove City';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeSubtitle => 'Scale all app text to your preferred size';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeSubtitle => 'Use a darker theme';

  @override
  String get useCelsius => 'Show temperatures in Celsius';

  @override
  String get useCelsiusSubtitle => 'Toggle between °F and °C';

  @override
  String get compactLayout => 'Compact layout';

  @override
  String get compactLayoutSubtitle => 'Reduce padding and card heights';

  @override
  String get enterCityName => 'Enter city name';

  @override
  String get currentCities => 'Current Cities';

  @override
  String get swipeToDelete => 'Swipe right to delete';

  @override
  String get delete => 'Delete';
}

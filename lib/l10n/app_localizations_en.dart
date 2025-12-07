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
  String get today => 'Today';

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

  @override
  String get now => 'Now';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get enableLocationSettingsHint => 'Enable location access in system settings.';

  @override
  String get cityRestorePartial => 'Some saved cities could not be restored. Pull to refresh.';

  @override
  String get loadSavedCitiesFailed => 'Failed to load saved cities.';

  @override
  String get cityNotFound => 'City not found';

  @override
  String get failedToAddCity => 'Failed to add city.';

  @override
  String failedToRefreshCity(Object city) {
    return 'Failed to refresh $city.';
  }

  @override
  String get cityAlreadyAdded => 'City already added';

  @override
  String weatherUnavailable(Object city) {
    return 'Weather data unavailable for $city.';
  }

  @override
  String networkIssueForCity(Object city) {
    return 'Network issue fetching $city. Check your connection.';
  }

  @override
  String unexpectedResponseForCity(Object city) {
    return 'Unexpected response for $city weather. Please retry.';
  }

  @override
  String parsingErrorForCity(Object city) {
    return 'Could not read weather data for $city. Try again later.';
  }

  @override
  String get locationServiceDisabled => 'Turn on location services to see local weather.';

  @override
  String get locationPermissionDenied => 'Location permission denied. Enable access and refresh.';

  @override
  String get locationPermissionPermanentlyDenied => 'Location permission denied permanently. Enable it in system settings.';

  @override
  String get locationTimeout => 'Timed out while getting your location. Pull to refresh to try again.';

  @override
  String get locationUnavailable => 'Location unavailable right now. Pull to refresh to retry.';

  @override
  String locationFallbackMessage(Object city, Object message) {
    return '$message Showing $city. Enable location and refresh.';
  }

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherMainlyClear => 'Mainly clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherOvercast => 'Overcast';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherRimeFog => 'Depositing rime fog';

  @override
  String get weatherLightDrizzle => 'Light drizzle';

  @override
  String get weatherModerateDrizzle => 'Moderate drizzle';

  @override
  String get weatherDenseDrizzle => 'Dense drizzle';

  @override
  String get weatherLightFreezingDrizzle => 'Light freezing drizzle';

  @override
  String get weatherFreezingDrizzle => 'Freezing drizzle';

  @override
  String get weatherSlightRain => 'Slight rain';

  @override
  String get weatherModerateRain => 'Moderate rain';

  @override
  String get weatherHeavyRain => 'Heavy rain';

  @override
  String get weatherLightFreezingRain => 'Light freezing rain';

  @override
  String get weatherFreezingRain => 'Freezing rain';

  @override
  String get weatherSlightSnowFall => 'Slight snow fall';

  @override
  String get weatherModerateSnowFall => 'Moderate snow fall';

  @override
  String get weatherHeavySnowFall => 'Heavy snow fall';

  @override
  String get weatherSnowGrains => 'Snow grains';

  @override
  String get weatherSlightRainShowers => 'Slight rain showers';

  @override
  String get weatherModerateRainShowers => 'Moderate rain showers';

  @override
  String get weatherViolentRainShowers => 'Violent rain showers';

  @override
  String get weatherSlightSnowShowers => 'Slight snow showers';

  @override
  String get weatherHeavySnowShowers => 'Heavy snow showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherThunderstormWithHail => 'Thunderstorm with hail';

  @override
  String get weatherHeavyThunderstormWithHail => 'Heavy thunderstorm with hail';
}

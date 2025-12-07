import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/city.dart';
import '../models/settings.dart';
import '../models/weather_failure.dart';
import '../repositories/city_repository.dart';
import '../repositories/weather_repository.dart';
import '../l10n/app_localizations.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class CityWeather {
  CityWeather({required this.city, required this.bundle});

  final City city;
  final WeatherBundle bundle;
}

@immutable
class WeatherState {
  const WeatherState({
    this.cities = const [],
    this.isLoading = false,
    this.error,
    this.selectedIndex = 0,
    this.lastLocationFailure,
    this.locale = const Locale('en'),
  });

  final List<CityWeather> cities;
  final bool isLoading;
  final String? error;
  final int selectedIndex;
  final LocationFailureReason? lastLocationFailure;
  final Locale locale;

  CityWeather? get selected =>
      cities.isEmpty ? null : cities[selectedIndex.clamp(0, cities.length - 1)];

  bool get canRequestLocation =>
      lastLocationFailure != LocationFailureReason.permissionPermanentlyDenied;

  WeatherState copyWith({
    List<CityWeather>? cities,
    bool? isLoading,
    Object? error = _noValue,
    int? selectedIndex,
    Object? lastLocationFailure = _noValue,
    Locale? locale,
  }) {
    return WeatherState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _noValue) ? this.error : error as String?,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      lastLocationFailure: identical(lastLocationFailure, _noValue)
          ? this.lastLocationFailure
          : lastLocationFailure as LocationFailureReason?,
      locale: locale ?? this.locale,
    );
  }
}

const _noValue = Object();

@immutable
class WeatherPresentation {
  const WeatherPresentation({
    required this.isLoading,
    required this.error,
    required this.lastLocationFailure,
    required this.canRequestLocation,
    required this.selectedIndex,
    required this.cities,
  });

  final bool isLoading;
  final String? error;
  final LocationFailureReason? lastLocationFailure;
  final bool canRequestLocation;
  final int selectedIndex;
  final List<CityPresentation> cities;

  CityPresentation? get selected =>
      cities.isEmpty ? null : cities[selectedIndex.clamp(0, cities.length - 1)];
}

@immutable
class CityPresentation {
  const CityPresentation({
    required this.id,
    required this.displayName,
    required this.conditionLabel,
    required this.isNight,
    required this.currentTemp,
    required this.unitLabel,
    required this.iconAsset,
    required this.hourly,
    required this.daily,
  });

  final String id;
  final String displayName;
  final String conditionLabel;
  final bool isNight;
  final double currentTemp;
  final String unitLabel;
  final String iconAsset;
  final List<HourlyForecastPresentation> hourly;
  final List<DailyForecastPresentation> daily;
}

@immutable
class HourlyForecastPresentation {
  const HourlyForecastPresentation({
    required this.label,
    required this.temperature,
    required this.unitLabel,
    required this.iconAsset,
    this.precipChance,
    this.isNight = false,
  });

  final String label;
  final double temperature;
  final String unitLabel;
  final String iconAsset;
  final int? precipChance;
  final bool isNight;
}

@immutable
class DailyForecastPresentation {
  const DailyForecastPresentation({
    required this.label,
    required this.high,
    required this.low,
    required this.unitLabel,
    required this.iconAsset,
    this.precipChance,
    this.isNight = false,
  });

  final String label;
  final double high;
  final double low;
  final String unitLabel;
  final String iconAsset;
  final int? precipChance;
  final bool isNight;
}

class WeatherViewModel extends ChangeNotifier {
  // Allow injecting repository/services for testing; defaults to real implementations
  final WeatherRepository _repository;
  final GeocodingService _geocoding;
  final LocationService _location;
  final CityRepository _cityRepository;
  WeatherState _state;

  WeatherViewModel({
    WeatherRepository? repository,
    GeocodingService? geocoding,
    LocationService? location,
    CityRepository? cityRepository,
    Locale? locale,
  }) : _repository = repository ?? HttpWeatherRepository(),
       _geocoding = geocoding ?? GeocodingService(),
       _location = location ?? LocationService(),
       _cityRepository = cityRepository ?? SharedPrefsCityRepository(),
       _state = WeatherState(locale: locale ?? const Locale('en'));

  WeatherState get state => _state;
  List<CityWeather> get cities => List.unmodifiable(_state.cities);
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  int get selectedIndex => _state.selectedIndex;
  CityWeather? get selected => _state.selected;
  LocationFailureReason? get lastLocationFailure => _state.lastLocationFailure;
  bool get canRequestLocation => _state.canRequestLocation;
  AppLocalizations get _strings {
    final match = AppLocalizations.supportedLocales.firstWhere(
      (l) => l.languageCode == _state.locale.languageCode,
      orElse: () => const Locale('en'),
    );
    return lookupAppLocalizations(match);
  }

  void updateLocale(Locale locale) {
    if (_state.locale.languageCode == locale.languageCode) return;
    _state = _state.copyWith(locale: locale);
  }

  Future<void> bootstrap() async {
    if (_state.isLoading) return;
    _setLoading(true);
    await _loadSavedCities();
    await ensureCurrentLocationCity(promptPermission: true);
    _setLoading(false);
  }

  Future<void> _loadSavedCities() async {
    try {
      final saved = await _cityRepository.load();
      if (saved.isEmpty) return;

      var restoreFailed = false;
      final updatedCities = List<CityWeather>.from(_state.cities);
      for (final city in saved) {
        final result = await _repository.getWeatherBundle(
          latitude: city.latitude,
          longitude: city.longitude,
        );
        if (result.isSuccess && result.value != null) {
          updatedCities.add(CityWeather(city: city, bundle: result.value!));
        } else {
          restoreFailed = true;
        }
      }

      _state = _state.copyWith(
        cities: updatedCities,
        selectedIndex: updatedCities.isNotEmpty ? 0 : _state.selectedIndex,
        error: restoreFailed ? _strings.cityRestorePartial : _state.error,
      );
    } catch (_) {
      _state = _state.copyWith(
        error: _state.error ?? _strings.loadSavedCitiesFailed,
      );
    }
    notifyListeners();
  }

  Future<void> addCityByName(String name) async {
    _setLoading(true);
    try {
      final city = await _geocoding.searchCity(name);
      if (city == null) {
        _state = _state.copyWith(error: _strings.cityNotFound);
      } else {
        await _addCity(city);
      }
    } catch (e) {
      _state = _state.copyWith(error: _strings.failedToAddCity);
    }
    _setLoading(false);
  }

  Future<void> addCityFromCoords(City city) async {
    _setLoading(true);
    try {
      await _addCity(city);
    } catch (e) {
      _state = _state.copyWith(error: _strings.failedToAddCity);
    }
    _setLoading(false);
  }

  Future<void> refreshCity(int index) async {
    if (index < 0 || index >= _state.cities.length) return;
    _setLoading(true);
    try {
      var cityWeather = _state.cities[index];
      City targetCity = cityWeather.city;

      // For current location, refresh coordinates before fetching weather.
      if (targetCity.name == 'Current Location') {
        final posResult = await _location.getCurrentPosition();
        _state = _state.copyWith(lastLocationFailure: posResult.error);
        if (posResult.position != null) {
          targetCity = City(
            name: 'Current Location',
            latitude: posResult.position!.latitude,
            longitude: posResult.position!.longitude,
          );
        } else {
          _state = _state.copyWith(
            error: _locationErrorMessage(posResult.error),
          );
          _setLoading(false);
          return;
        }
      }

      final result = await _repository.getWeatherBundle(
        latitude: targetCity.latitude,
        longitude: targetCity.longitude,
      );
      if (result.isSuccess && result.value != null) {
        final bundle = result.value!;
        final updated = List<CityWeather>.from(_state.cities);
        updated[index] = CityWeather(city: targetCity, bundle: bundle);
        _state = _state.copyWith(
          cities: updated,
          error: null,
          lastLocationFailure: null,
        );
        await _persistCities();
      } else {
        _state = _state.copyWith(
          error: _weatherErrorMessage(targetCity.name, result.failure),
        );
      }
    } catch (e) {
      final name = _state.cities[index].city.name;
      _state = _state.copyWith(error: _strings.failedToRefreshCity(name));
    }
    _setLoading(false);
  }

  void selectCity(int index) {
    if (index < 0 || index >= _state.cities.length) return;
    _state = _state.copyWith(selectedIndex: index);
    notifyListeners();
  }

  Future<void> ensureCurrentLocationCity({
    bool promptPermission = false,
  }) async {
    if (promptPermission) {
      await _promptForPermission();
    }

    final locationResult = await _location.getCurrentPosition();
    _state = _state.copyWith(lastLocationFailure: locationResult.error);
    if (locationResult.position != null) {
      final city = City(
        name: 'Current Location',
        latitude: locationResult.position!.latitude,
        longitude: locationResult.position!.longitude,
      );
      final existingIndex = _state.cities.indexWhere(
        (c) => c.city.name == 'Current Location',
      );
      if (existingIndex >= 0) {
        await refreshCity(existingIndex);
      } else {
        await _addCity(city);
      }
      _state = _state.copyWith(lastLocationFailure: null);
      return;
    }

    if (_state.cities.isEmpty) {
      const fallbackCity = City(
        name: 'Pittsburgh',
        latitude: 40.4406,
        longitude: -79.9959,
      );
      await _addCity(fallbackCity);
      final message = _locationErrorMessage(locationResult.error);
      _state = _state.copyWith(
        error: _strings.locationFallbackMessage(fallbackCity.name, message),
      );
      notifyListeners();
    } else {
      _state = _state.copyWith(
        error: _locationErrorMessage(locationResult.error),
      );
      notifyListeners();
    }
  }

  Future<void> requestLocationAccess() async {
    if (_state.isLoading) return;
    _setLoading(true);
    await _promptForPermission(force: true);
    await ensureCurrentLocationCity();
    _setLoading(false);
  }

  Future<void> openLocationSettings() async {
    await _location.openAppSettings();
  }

  Future<void> _addCity(City city) async {
    if (_state.cities.any(
      (c) => c.city.name.toLowerCase() == city.name.toLowerCase(),
    )) {
      _state = _state.copyWith(error: _strings.cityAlreadyAdded);
      return;
    }

    final result = await _repository.getWeatherBundle(
      latitude: city.latitude,
      longitude: city.longitude,
    );
    if (!result.isSuccess || result.value == null) {
      _state = _state.copyWith(
        error: _weatherErrorMessage(city.name, result.failure),
      );
      return;
    }

    final updatedCities = List<CityWeather>.from(_state.cities)
      ..add(CityWeather(city: city, bundle: result.value!));
    _state = _state.copyWith(
      cities: updatedCities,
      error: null,
      selectedIndex: updatedCities.length - 1,
    );
    await _persistCities();
    notifyListeners();
  }

  Future<void> removeCity(int index) async {
    if (index < 0 || index >= _state.cities.length) return;
    final updated = List<CityWeather>.from(_state.cities)..removeAt(index);
    final nextIndex =
        _state.selectedIndex >= updated.length && updated.isNotEmpty
        ? updated.length - 1
        : _state.selectedIndex.clamp(0, updated.length);
    _state = _state.copyWith(cities: updated, selectedIndex: nextIndex);
    await _persistCities();
    notifyListeners();
  }

  Future<void> _persistCities() async {
    try {
      await _cityRepository.save(_state.cities.map((c) => c.city).toList());
    } catch (_) {
      // Ignore persistence failures to keep UI responsive.
    }
  }

  void _setLoading(bool value, {bool silent = false}) {
    _state = _state.copyWith(isLoading: value);
    if (!silent) {
      notifyListeners();
    }
  }

  String _weatherErrorMessage(String cityName, WeatherFailure? failure) {
    if (failure == null) return _strings.weatherUnavailable(cityName);
    switch (failure.reason) {
      case WeatherFailureReason.network:
        return _strings.networkIssueForCity(cityName);
      case WeatherFailureReason.invalidResponse:
        return _strings.unexpectedResponseForCity(cityName);
      case WeatherFailureReason.parsing:
        return _strings.parsingErrorForCity(cityName);
      case WeatherFailureReason.unknown:
        return _strings.weatherUnavailable(cityName);
    }
  }

  String _locationErrorMessage(LocationFailureReason? reason) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return _strings.locationServiceDisabled;
      case LocationFailureReason.permissionDenied:
        return _strings.locationPermissionDenied;
      case LocationFailureReason.permissionPermanentlyDenied:
        return _strings.locationPermissionPermanentlyDenied;
      case LocationFailureReason.timeout:
        return _strings.locationTimeout;
      case LocationFailureReason.unavailable:
        return _strings.locationUnavailable;
      case null:
        return _strings.locationUnavailable;
    }
  }

  WeatherPresentation toPresentation(Settings settings, AppLocalizations l10n) {
    final unitLabel = _unitLabel(settings.useCelsius);
    final localeTag = state.locale.toLanguageTag();
    final hourFormatter = DateFormat.j(localeTag);
    final dayFormatter = DateFormat.E(localeTag);

    final cityPresentations = <CityPresentation>[];
    for (final cityWeather in _state.cities) {
      final bundle = cityWeather.bundle;
      final isNightNow = _isNight(bundle.current.time);
      final currentTemp = _displayTemp(
        bundle.current.temperature,
        settings.useCelsius,
      );
      final displayName = _localizedCityName(cityWeather.city, l10n);
      final conditionLabel = _localizedConditionLabel(
        bundle.current.code,
        l10n,
      );

      final hourlyEntries = _buildHourly(
        bundle,
        settings.useCelsius,
        unitLabel,
        l10n,
        hourFormatter,
      );
      final dailyEntries = _buildDaily(
        bundle,
        settings.useCelsius,
        unitLabel,
        l10n,
        dayFormatter,
      );

      cityPresentations.add(
        CityPresentation(
          id: cityWeather.city.name,
          displayName: displayName,
          conditionLabel: conditionLabel,
          isNight: isNightNow,
          currentTemp: currentTemp,
          unitLabel: unitLabel,
          iconAsset: _iconAssetForCode(
            bundle.current.code,
            isNight: isNightNow,
          ),
          hourly: hourlyEntries,
          daily: dailyEntries,
        ),
      );
    }

    final safeIndex = cityPresentations.isEmpty
        ? 0
        : _state.selectedIndex.clamp(0, cityPresentations.length - 1);

    return WeatherPresentation(
      isLoading: _state.isLoading,
      error: _state.error,
      lastLocationFailure: _state.lastLocationFailure,
      canRequestLocation: _state.canRequestLocation,
      selectedIndex: safeIndex,
      cities: cityPresentations,
    );
  }

  Future<void> _promptForPermission({bool force = false}) async {
    var status = await _location.checkPermission();
    final needsRequest =
        force ||
        status == LocationPermission.denied ||
        status == LocationPermission.unableToDetermine;
    if (needsRequest) {
      status = await _location.requestPermission();
    }

    if (status == LocationPermission.denied) {
      _state = _state.copyWith(
        lastLocationFailure: LocationFailureReason.permissionDenied,
        error: _locationErrorMessage(LocationFailureReason.permissionDenied),
      );
    } else if (status == LocationPermission.deniedForever) {
      _state = _state.copyWith(
        lastLocationFailure: LocationFailureReason.permissionPermanentlyDenied,
        error: _locationErrorMessage(
          LocationFailureReason.permissionPermanentlyDenied,
        ),
      );
    }
  }
}

List<HourlyForecastPresentation> _buildHourly(
  WeatherBundle bundle,
  bool useCelsius,
  String unitLabel,
  AppLocalizations l10n,
  DateFormat hourFormatter,
) {
  final hourlyTimes = bundle.hourly.times;
  final hourlyTemps = bundle.hourly.temperatures;
  final hourlyCodes = bundle.hourly.codes;
  final currentTime = bundle.current.time;
  int start = 0;

  if (currentTime != null) {
    start = hourlyTimes.indexWhere((t) => t.isAtSameMomentAs(currentTime));
    if (start == -1) {
      start = _closestIndex(hourlyTimes, currentTime);
    }
  }

  int displayCount = hourlyTimes.length - start;
  if (displayCount > 24) displayCount = 24;
  if (displayCount <= 0) displayCount = hourlyTimes.length;

  final entries = <HourlyForecastPresentation>[];
  for (var hourIndex = 0; hourIndex < displayCount; hourIndex++) {
    final actualIndex = start + hourIndex;
    final time = hourlyTimes[actualIndex];
    final code = hourlyCodes[actualIndex];
    final precipRaw =
        bundle.hourly.precipitationProbability.length > actualIndex
        ? bundle.hourly.precipitationProbability[actualIndex]
        : 0;
    final precip = _roundToNearestFive(precipRaw);
    final showPrecip = _isPrecipitation(code) && precip > 0;
    final label = hourIndex == 0
        ? l10n.now
        : hourFormatter.format(time.toLocal());
    final rawTemp = hourIndex == 0
        ? bundle.current.temperature
        : hourlyTemps[actualIndex];
    final displayTemp = _displayTemp(rawTemp, useCelsius);

    entries.add(
      HourlyForecastPresentation(
        label: label,
        temperature: displayTemp,
        unitLabel: unitLabel,
        iconAsset: _iconAssetForCode(code, isNight: _isNight(time)),
        precipChance: showPrecip ? precip : null,
        isNight: _isNight(time),
      ),
    );
  }
  return entries;
}

List<DailyForecastPresentation> _buildDaily(
  WeatherBundle bundle,
  bool useCelsius,
  String unitLabel,
  AppLocalizations l10n,
  DateFormat dayFormatter,
) {
  final entries = <DailyForecastPresentation>[];
  final currentTime = bundle.current.time;
  for (var dayIndex = 0; dayIndex < bundle.daily.times.length; dayIndex++) {
    final dayTime = bundle.daily.times[dayIndex];
    final label = _isToday(dayTime)
        ? l10n.today
        : dayFormatter.format(dayTime.toLocal());
    final code = bundle.daily.codes[dayIndex];
    final precipRaw = bundle.daily.precipitationProbabilityMax.length > dayIndex
        ? bundle.daily.precipitationProbabilityMax[dayIndex]
        : 0;
    final precip = _roundToNearestFive(precipRaw);
    final hasPrecip = _isPrecipitation(code) && precip > 0;
    entries.add(
      DailyForecastPresentation(
        label: label,
        high: _displayTemp(bundle.daily.tempMax[dayIndex], useCelsius),
        low: _displayTemp(bundle.daily.tempMin[dayIndex], useCelsius),
        unitLabel: unitLabel,
        iconAsset: _iconAssetForCode(
          code,
          isNight: _isNightForDay(dayTime, currentTime),
        ),
        precipChance: hasPrecip ? precip : null,
        isNight: _isNightForDay(dayTime, currentTime),
      ),
    );
  }
  return entries;
}

String _iconAssetForCode(int code, {required bool isNight}) {
  if (_isThunderstorm(code)) {
    const hailCodes = {96, 99};
    return hailCodes.contains(code)
        ? 'icons/thunderstorm-with-hail.png'
        : 'icons/thunderstorm.png';
  }

  if (_isPrecipitation(code)) {
    const snowCodes = {71, 73, 75, 77, 85, 86};
    return snowCodes.contains(code) ? 'icons/snow.png' : 'icons/rain.png';
  }

  switch (code) {
    case 0:
      return isNight ? 'icons/clear-night.png' : 'icons/sunny.png';
    case 1:
    case 2:
      return isNight ? 'icons/cloudy-night.png' : 'icons/partly-cloudy.png';
    case 3:
    case 45:
    case 48:
      return isNight ? 'icons/cloudy-night.png' : 'icons/partly-cloudy.png';
    default:
      return isNight ? 'icons/cloudy-night.png' : 'icons/partly-cloudy.png';
  }
}

bool _isThunderstorm(int code) => {95, 96, 99}.contains(code);

bool _isPrecipitation(int code) {
  const precipCodes = {
    51, 53, 55, 56, 57, // drizzle / freezing drizzle
    61, 63, 65, 66, 67, // rain / freezing rain
    71, 73, 75, 77, 85, 86, // snow
    80, 81, 82, // rain showers
    95, 96, 99, // thunderstorms
  };
  return precipCodes.contains(code);
}

int _roundToNearestFive(int value) => (value / 5).round() * 5;

double _displayTemp(double tempF, bool useCelsius) =>
    useCelsius ? (tempF - 32) * 5 / 9 : tempF;

String _unitLabel(bool useCelsius) => useCelsius ? '°C' : '°F';

String _localizedCityName(City city, AppLocalizations l10n) =>
    city.name == 'Current Location' ? l10n.currentLocation : city.name;

String _localizedConditionLabel(int code, AppLocalizations l10n) {
  switch (code) {
    case 0:
      return l10n.weatherClear;
    case 1:
      return l10n.weatherMainlyClear;
    case 2:
      return l10n.weatherPartlyCloudy;
    case 3:
      return l10n.weatherOvercast;
    case 45:
      return l10n.weatherFog;
    case 48:
      return l10n.weatherRimeFog;
    case 51:
      return l10n.weatherLightDrizzle;
    case 53:
      return l10n.weatherModerateDrizzle;
    case 55:
      return l10n.weatherDenseDrizzle;
    case 56:
      return l10n.weatherLightFreezingDrizzle;
    case 57:
      return l10n.weatherFreezingDrizzle;
    case 61:
      return l10n.weatherSlightRain;
    case 63:
      return l10n.weatherModerateRain;
    case 65:
      return l10n.weatherHeavyRain;
    case 66:
      return l10n.weatherLightFreezingRain;
    case 67:
      return l10n.weatherFreezingRain;
    case 71:
      return l10n.weatherSlightSnowFall;
    case 73:
      return l10n.weatherModerateSnowFall;
    case 75:
      return l10n.weatherHeavySnowFall;
    case 77:
      return l10n.weatherSnowGrains;
    case 80:
      return l10n.weatherSlightRainShowers;
    case 81:
      return l10n.weatherModerateRainShowers;
    case 82:
      return l10n.weatherViolentRainShowers;
    case 85:
      return l10n.weatherSlightSnowShowers;
    case 86:
      return l10n.weatherHeavySnowShowers;
    case 95:
      return l10n.weatherThunderstorm;
    case 96:
      return l10n.weatherThunderstormWithHail;
    case 99:
      return l10n.weatherHeavyThunderstormWithHail;
    default:
      return l10n.weatherPartlyCloudy;
  }
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

bool _isNight(DateTime? time) {
  if (time == null) return false;
  final hour = time.toLocal().hour;
  return hour >= 18 || hour < 6;
}

bool _isNightForDay(DateTime day, DateTime? currentTime) {
  if (currentTime == null) return false;
  final isSameDay =
      day.year == currentTime.year &&
      day.month == currentTime.month &&
      day.day == currentTime.day;
  return isSameDay && _isNight(currentTime);
}

int _closestIndex(List<DateTime> times, DateTime target) {
  if (times.isEmpty) return 0;
  int bestIndex = 0;
  Duration bestDiff = times.first.difference(target).abs();

  for (var i = 1; i < times.length; i++) {
    final diff = times[i].difference(target).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      bestIndex = i;
    }
  }
  return bestIndex;
}

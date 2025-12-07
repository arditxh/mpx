import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String _iconAssetForCode(int code, {required bool isNight}) {
  // Map Open-Meteo weather codes to local assets.
  if (_isPrecipitation(code)) {
    // Snow codes
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cityController = TextEditingController();
  final _pageController = PageController();
  int _lastCityCount = 0;
  bool _dialogSwipeHintShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherViewModel>(context, listen: false).bootstrap();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ignore: unused_local_variable
    final settings = context.watch<SettingsViewModel>().settings;
    return Scaffold(
      appBar: AppBar(
        //title: const Text('Weather'), older one
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          Consumer<WeatherViewModel>(
            builder: (context, vm, _) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: vm.selectedIndex < vm.cities.length
                    ? () => vm.refreshCity(vm.selectedIndex)
                    : null,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCityDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<WeatherViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.cities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.cities.isEmpty) {
            return _EmptyState(
              error: vm.error,
              onAdd: _showAddCityDialog,
              onUseLocation: vm.lastLocationFailure != null
                  ? (vm.canRequestLocation
                        ? vm.requestLocationAccess
                        : vm.openLocationSettings)
                  : null,
            );
          }

          final useCelsius = settings.useCelsius;
          final compactLayout = settings.compactLayout;
          final cardSpacing = compactLayout ? 16.0 : 24.0;
          final basePadding = compactLayout ? 12.0 : 16.0;
          final listPadding = EdgeInsets.fromLTRB(
            basePadding,
            basePadding,
            basePadding,
            basePadding + 40,
          );

          final targetIndex = vm.selectedIndex.clamp(0, vm.cities.length - 1);
          // Only jump pages when the list of cities changes (e.g., add/remove).
          if (_lastCityCount != vm.cities.length) {
            _lastCityCount = vm.cities.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(targetIndex);
              }
            });
          }

          return Column(
            children: [
              if (vm.isLoading) const LinearProgressIndicator(minHeight: 3),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (vm.lastLocationFailure != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: Text(
                                vm.canRequestLocation
                                    ? 'Use my location'
                                    : 'Open Settings',
                              ),
                              onPressed: vm.canRequestLocation
                                  ? vm.requestLocationAccess
                                  : vm.openLocationSettings,
                            ),
                            if (!vm.canRequestLocation)
                              const Text(
                                'Enable location access in system settings.',
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: vm.selectCity,
                  itemCount: vm.cities.length,
                  itemBuilder: (context, index) {
                    final cityWeather = vm.cities[index];
                    return RefreshIndicator(
                      onRefresh: () => vm.refreshCity(index),
                      child: ListView(
                        padding: listPadding,
                        children: [
                          _CurrentConditionsCard(
                            weather: cityWeather.bundle.current,
                            cityName: cityWeather.city.name,
                            isNight: _isNight(cityWeather.bundle.current.time),
                            useCelsius: useCelsius,
                          ),
                          SizedBox(height: cardSpacing),
                          Text(
                            //'Hourly', older one
                            l10n.hourly,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: compactLayout ? 8 : 12),
                          Builder(
                            builder: (context) {
                              final textScale = MediaQuery.textScaleFactorOf(
                                context,
                              );
                              final baseHeight = compactLayout ? 135.0 : 155.0;
                              // Grow with larger text to avoid overflow at high scales.
                              final scaledHeight = (baseHeight * textScale)
                                  .clamp(baseHeight, baseHeight * 1.8);

                              final hourlyTimes =
                                  cityWeather.bundle.hourly.times;
                              final hourlyTemps =
                                  cityWeather.bundle.hourly.temperatures;
                              final hourlyCodes =
                                  cityWeather.bundle.hourly.codes;
                              final currentTime =
                                  cityWeather.bundle.current.time;
                              int start = 0;

                              if (currentTime != null) {
                                start = hourlyTimes.indexWhere(
                                  (t) => t.isAtSameMomentAs(currentTime),
                                );
                                if (start == -1) {
                                  start = _closestIndex(
                                    hourlyTimes,
                                    currentTime,
                                  );
                                }
                              }

                              int displayCount = hourlyTimes.length - start;
                              if (displayCount > 24) displayCount = 24;
                              if (displayCount <= 0)
                                displayCount = hourlyTimes.length;

                              return SizedBox(
                                height: scaledHeight,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: displayCount,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: compactLayout ? 8 : 12),
                                  itemBuilder: (context, hourIndex) {
                                    final actualIndex = start + hourIndex;
                                    final time = hourlyTimes[actualIndex];
                                    final code = hourlyCodes[actualIndex];
                                    final precipRaw =
                                        cityWeather
                                                .bundle
                                                .hourly
                                                .precipitationProbability
                                                .length >
                                            actualIndex
                                        ? cityWeather
                                              .bundle
                                              .hourly
                                              .precipitationProbability[actualIndex]
                                        : 0;
                                    final precip = _roundToNearestFive(
                                      precipRaw,
                                    );
                                    final showPrecip =
                                        _isPrecipitation(code) && precip > 0;
                                    final label = hourIndex == 0
                                        ? 'Now'
                                        : _formatHour(time);
                                    final rawTemp = hourIndex == 0
                                        ? cityWeather.bundle.current.temperature
                                        : hourlyTemps[actualIndex];
                                    final displayTemp = _displayTemp(
                                      rawTemp,
                                      useCelsius,
                                    );
                                    return _HourlyTile(
                                      label: label,
                                      temperature: displayTemp,
                                      code: code,
                                      precipChance: showPrecip ? precip : null,
                                      unitLabel: _unitLabel(useCelsius),
                                      isNight: _isNight(time),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: cardSpacing),
                          Text(
                            //'Daily', older one
                            l10n.dailyForecast,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: compactLayout ? 8 : 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cityWeather.bundle.daily.times.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, dayIndex) {
                              return _DailyTile(
                                label:
                                    _isToday(
                                      cityWeather.bundle.daily.times[dayIndex],
                                    )
                                    ? l10n.today
                                    : _formatDay(
                                        context,
                                        cityWeather
                                            .bundle
                                            .daily
                                            .times[dayIndex],
                                      ),
                                high: _displayTemp(
                                  cityWeather.bundle.daily.tempMax[dayIndex],
                                  useCelsius,
                                ),
                                low: _displayTemp(
                                  cityWeather.bundle.daily.tempMin[dayIndex],
                                  useCelsius,
                                ),
                                code: cityWeather.bundle.daily.codes[dayIndex],
                                precipChance: () {
                                  final raw =
                                      cityWeather
                                              .bundle
                                              .daily
                                              .precipitationProbabilityMax
                                              .length >
                                          dayIndex
                                      ? cityWeather
                                            .bundle
                                            .daily
                                            .precipitationProbabilityMax[dayIndex]
                                      : 0;
                                  final rounded = _roundToNearestFive(raw);
                                  final hasPrecip =
                                      _isPrecipitation(
                                        cityWeather
                                            .bundle
                                            .daily
                                            .codes[dayIndex],
                                      ) &&
                                      rounded > 0;
                                  return hasPrecip ? rounded : null;
                                }(),
                                isNight: _isNightForDay(
                                  cityWeather.bundle.daily.times[dayIndex],
                                  cityWeather.bundle.current.time,
                                ),
                                compact: compactLayout,
                                unitLabel: _unitLabel(useCelsius),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _PageIndicator(
                count: vm.cities.length,
                index: vm.selectedIndex,
                onTap: (i) {
                  vm.selectCity(i);
                  _pageController.jumpToPage(i);
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  String _formatHour(DateTime time) {
    // API returns hours in local time for the coordinates; format to a friendly 12h label.
    final hour = time.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '$displayHour $suffix';
  }

  String _formatDay(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat.E(locale);
    return formatter.format(date.toLocal());
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

  Future<void> _showAddCityDialog() async {
    final vm = Provider.of<WeatherViewModel>(context, listen: false);
    _cityController.clear();
    final shouldShowSwipeHint = !_dialogSwipeHintShown && vm.cities.isNotEmpty;
    bool hintVisible = shouldShowSwipeHint;
    bool hintHideScheduled = false;
    if (shouldShowSwipeHint) {
      _dialogSwipeHintShown = true;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final animatedListKey = GlobalKey<AnimatedListState>();

        return AlertDialog(
          title: Text(l10n.addRemoveCity), //Text('Add / Remove City'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              if (shouldShowSwipeHint && !hintHideScheduled) {
                hintHideScheduled = true;
                Future.delayed(const Duration(seconds: 3), () {
                  if (!hintVisible) return;
                  if (!context.mounted) return;
                  setStateSB(() {
                    hintVisible = false;
                  });
                });
              }
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: l10n.enterCityName, //'Enter city name',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.currentCities, //'Current Cities:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (hintVisible) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // got rid of const
                          Icon(Icons.swipe_right, size: 16),
                          SizedBox(width: 16),
                          //Text('Swipe right to delete'),
                          Text(l10n.swipeToDelete),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 200,
                      child: AnimatedList(
                        key: animatedListKey,
                        initialItemCount: vm.cities.length,
                        itemBuilder: (context, index, animation) {
                          final city = vm.cities[index];

                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          );

                          return FadeTransition(
                            opacity: curved,
                            child: Dismissible(
                              key: ValueKey(city.city.name),
                              direction: DismissDirection.startToEnd,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      //'Delete',
                                      l10n.delete,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                _removeCityAt(
                                  vm,
                                  animatedListKey,
                                  index,
                                  setStateSB,
                                  animate: false,
                                );
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(city.city.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeCityAt(
                                    vm,
                                    animatedListKey,
                                    index,
                                    setStateSB,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel), //const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _cityController.text.trim();
                if (name.isNotEmpty) {
                  await vm.addCityByName(name);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.add), // const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeCityAt(
    WeatherViewModel vm,
    GlobalKey<AnimatedListState> listKey,
    int index,
    void Function(void Function()) setStateSB, {
    bool animate = true,
  }) {
    if (index < 0 || index >= vm.cities.length) return;
    final removedCity = vm.cities[index];

    vm.removeCity(index);

    listKey.currentState?.removeItem(index, (context, animation) {
      if (!animate) {
        return const SizedBox.shrink();
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );
      return FadeTransition(
        opacity: curved,
        child: SizeTransition(
          sizeFactor: curved,
          axisAlignment: -1,
          child: ListTile(
            title: Text(
              removedCity.city.name,
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
        ),
      );
    }, duration: animate ? const Duration(milliseconds: 300) : Duration.zero);

    setStateSB(() {});
  }
}

class _CurrentConditionsCard extends StatelessWidget {
  const _CurrentConditionsCard({
    required this.weather,
    required this.cityName,
    required this.isNight,
    required this.useCelsius,
  });

  final Weather weather;
  final String cityName;
  final bool isNight;
  final bool useCelsius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTemp = _displayTemp(weather.temperature, useCelsius);
    final unitLabel = _unitLabel(useCelsius);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cityName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayTemp.toStringAsFixed(1),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(unitLabel, style: theme.textTheme.titleLarge),
                    ),
                  ],
                ),
              ),
              _WeatherIcon(code: weather.code, size: 56, isNight: isNight),
            ],
          ),
          const SizedBox(height: 8),
          Text(weather.condition, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _HourlyTile extends StatelessWidget {
  const _HourlyTile({
    required this.label,
    required this.temperature,
    required this.code,
    required this.unitLabel,
    this.precipChance,
    this.isNight = false,
  });

  final String label;
  final double temperature;
  final int code;
  final String unitLabel;
  final int? precipChance;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScaleFactorOf(context);
    final tileWidth = (90 * textScale).clamp(90.0, 120.0).toDouble();
    final tempText = '${temperature.toStringAsFixed(0)}$unitLabel';
    final iconSize = (32 * textScale).clamp(28.0, 44.0);
    return Container(
      width: tileWidth,
      padding: EdgeInsets.all(textScale >= 1.3 ? 12 : 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          SizedBox(height: textScale >= 1.2 ? 8 : 6),
          _WeatherIcon(
            code: code,
            isNight: isNight,
            size: iconSize,
          ),
          SizedBox(height: textScale >= 1.2 ? 8 : 6),
          if (precipChance != null) ...[
            Text('$precipChance%', style: theme.textTheme.bodySmall),
            SizedBox(height: textScale >= 1.2 ? 6 : 4),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tempText,
              softWrap: false,
              style: theme.textTheme.titleLarge?.copyWith(
                height: textScale > 1.3 ? 1.05 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({
    required this.label,
    required this.high,
    required this.low,
    required this.code,
    this.precipChance,
    this.isNight = false,
    required this.compact,
    required this.unitLabel,
  });

  final String label;
  final double high;
  final double low;
  final int code;
  final int? precipChance;
  final bool isNight;
  final bool compact;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScaleFactorOf(context);
    final labelWidth = (60 * textScale).clamp(60.0, 100.0);
    final iconSize = (20 * textScale).clamp(20.0, 28.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          _WeatherIcon(code: code, size: iconSize, isNight: isNight),
          if (precipChance != null) ...[
            const SizedBox(width: 6),
            Text('$precipChance%', style: theme.textTheme.bodySmall),
          ],
          const Spacer(),
          Text(
            '${low.toStringAsFixed(0)}$unitLabel',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          Text(
            '${high.toStringAsFixed(0)}$unitLabel',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({
    required this.code,
    this.size = 32,
    this.isNight = false,
  });

  final int code;
  final double size;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final asset = _iconAssetForCode(code, isNight: isNight);
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.error,
    required this.onAdd,
    this.onUseLocation,
  });

  final String? error;
  final VoidCallback onAdd;
  final VoidCallback? onUseLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //const Text('No cities yet'), older one
            Text(l10n.noData),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            if (onUseLocation != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                onPressed: onUseLocation,
                label: Text(
                  l10n.useMyLocation,
                ), //const Text('Use my location'),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAdd,
              child: Text(l10n.addCity),
            ), //const Text('Add a city')),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.index,
    required this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 12 : 8,
            height: active ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }
}

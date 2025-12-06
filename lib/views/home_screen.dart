import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../viewmodels/weather_viewmodel.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cityController = TextEditingController();
  final _pageController = PageController();
  int _lastCityCount = 0;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
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
            return _EmptyState(error: vm.error, onAdd: _showAddCityDialog);
          }

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
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    vm.error!,
                    style: const TextStyle(color: Colors.red),
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
                        padding: const EdgeInsets.all(16),
                        children: [
                          _CurrentConditionsCard(
                            weather: cityWeather.bundle.current,
                            cityName: cityWeather.city.name,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Hourly',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 150,
                            child: Builder(
                              builder: (context) {
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

                                return ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: displayCount,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
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
                                  return _HourlyTile(
                                    label: label,
                                    temperature: hourIndex == 0
                                        ? cityWeather
                                                .bundle
                                                .current
                                                .temperature
                                        : hourlyTemps[actualIndex],
                                    code: code,
                                    precipChance: showPrecip ? precip : null,
                                    isNight: _isNight(time),
                                  );
                                },
                              );
                            },
                          ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Daily',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cityWeather.bundle.daily.times.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, dayIndex) {
                              return _DailyTile(
                                label: _formatDay(
                                  cityWeather.bundle.daily.times[dayIndex],
                                ),
                                high:
                                    cityWeather.bundle.daily.tempMax[dayIndex],
                                low: cityWeather.bundle.daily.tempMin[dayIndex],
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
                                  return _isPrecipitation(
                                            cityWeather
                                                .bundle
                                                .daily
                                                .codes[dayIndex],
                                          ) &&
                                          rounded > 0
                                      ? rounded
                                      : null;
                                }(),
                                isNight: _isNightForDay(
                                  cityWeather.bundle.daily.times[dayIndex],
                                  cityWeather.bundle.current.time,
                                ),
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

  String _formatDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  bool _isNight(DateTime? time) {
    if (time == null) return false;
    final hour = time.toLocal().hour;
    return hour >= 18 || hour < 6;
  }

  bool _isNightForDay(DateTime day, DateTime? currentTime) {
    if (currentTime == null) return false;
    final isSameDay =
        day.year == currentTime.year && day.month == currentTime.month && day.day == currentTime.day;
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

  await showDialog<void>(
    context: context,
    builder: (context) {
      final animatedListKey = GlobalKey<AnimatedListState>();

      return AlertDialog(
        title: const Text('Add / Remove City'),
        content: StatefulBuilder(
          builder: (context, setStateSB) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      hintText: 'Enter city name',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Current Cities:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
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
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(city.city.name),
                            trailing: const Icon(Icons.delete_outline),
                            onTap: () {
                              final removedCity = vm.cities[index];

                              vm.removeCity(index);

                              animatedListKey.currentState!.removeItem(
                                index,
                                (context, animation) {
                                  final curved = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  );

                                  return FadeTransition(
                                    opacity: curved,
                                    child: ListTile(
                                      title: Text(
                                        removedCity.city.name,
                                        style: const TextStyle(
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                duration: const Duration(milliseconds: 350),
                              );

                              setStateSB(() {});
                            },
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _cityController.text.trim();
              if (name.isNotEmpty) {
                await vm.addCityByName(name);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}




}

class _CurrentConditionsCard extends StatelessWidget {
  const _CurrentConditionsCard({required this.weather, required this.cityName});

  final Weather weather;
  final String cityName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text(
                weather.temperature.toStringAsFixed(1),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('°F', style: theme.textTheme.titleLarge),
              ),
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
    this.precipChance,
    this.isNight = false,
  });

  final String label;
  final double temperature;
  final int code;
  final int? precipChance;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          _WeatherIcon(code: code, isNight: isNight),
          const SizedBox(height: 6),
          if (precipChance != null) ...[
            Text('$precipChance%', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
          ],
          Text(
            '${temperature.toStringAsFixed(0)}°',
            style: theme.textTheme.titleLarge,
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
  });

  final String label;
  final double high;
  final double low;
  final int code;
  final int? precipChance;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          _WeatherIcon(code: code, size: 20, isNight: isNight),
          if (precipChance != null) ...[
            const SizedBox(width: 6),
            Text('$precipChance%', style: theme.textTheme.bodySmall),
          ],
          const Spacer(),
          Text('${low.toStringAsFixed(0)}°', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Text(
            '${high.toStringAsFixed(0)}°',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({required this.code, this.size = 32, this.isNight = false});

  final int code;
  final double size;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final asset = _iconAssetForCode(code, isNight: isNight);
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.error, required this.onAdd});

  final String? error;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No cities yet'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onAdd, child: const Text('Add a city')),
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

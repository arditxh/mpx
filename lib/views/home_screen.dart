import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsViewModel>().settings;
    context.read<WeatherViewModel>().updateLocale(
      Localizations.localeOf(context),
    );
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
          final presentation = vm.toPresentation(settings, l10n);

          if (presentation.isLoading && presentation.cities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (presentation.cities.isEmpty) {
            return _EmptyState(
              error: presentation.error,
              onAdd: _showAddCityDialog,
              onUseLocation: presentation.lastLocationFailure != null
                  ? (presentation.canRequestLocation
                        ? vm.requestLocationAccess
                        : vm.openLocationSettings)
                  : null,
            );
          }

          final compactLayout = settings.compactLayout;
          final cardSpacing = compactLayout ? 16.0 : 24.0;
          final basePadding = compactLayout ? 12.0 : 16.0;
          final listPadding = EdgeInsets.fromLTRB(
            basePadding,
            basePadding,
            basePadding,
            basePadding + 40,
          );

          final targetIndex = presentation.selectedIndex.clamp(
            0,
            presentation.cities.length - 1,
          );
          // Only jump pages when the list of cities changes (e.g., add/remove).
          if (_lastCityCount != presentation.cities.length) {
            _lastCityCount = presentation.cities.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(targetIndex);
              }
            });
          }

          return Column(
            children: [
              if (presentation.isLoading)
                const LinearProgressIndicator(minHeight: 3),
              if (presentation.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (presentation.lastLocationFailure != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: Text(
                                presentation.canRequestLocation
                                    ? l10n.useMyLocation
                                    : l10n.openSettings,
                              ),
                              onPressed: presentation.canRequestLocation
                                  ? vm.requestLocationAccess
                                  : vm.openLocationSettings,
                            ),
                            if (!presentation.canRequestLocation)
                              Text(
                                l10n.enableLocationSettingsHint,
                                style: const TextStyle(color: Colors.red),
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
                  itemCount: presentation.cities.length,
                  itemBuilder: (context, index) {
                    final cityWeather = presentation.cities[index];
                    return RefreshIndicator(
                      onRefresh: () => vm.refreshCity(index),
                      child: ListView(
                        padding: listPadding,
                        children: [
                          _CurrentConditionsCard(
                            cityName: cityWeather.displayName,
                            conditionLabel: cityWeather.conditionLabel,
                            temperature: cityWeather.currentTemp,
                            unitLabel: cityWeather.unitLabel,
                            iconAsset: cityWeather.iconAsset,
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

                              return SizedBox(
                                height: scaledHeight,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cityWeather.hourly.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: compactLayout ? 8 : 12),
                                  itemBuilder: (context, hourIndex) {
                                    final hour = cityWeather.hourly[hourIndex];
                                    return _HourlyTile(
                                      label: hour.label,
                                      temperature: hour.temperature,
                                      unitLabel: hour.unitLabel,
                                      precipChance: hour.precipChance,
                                      iconAsset: hour.iconAsset,
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
                            itemCount: cityWeather.daily.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, dayIndex) {
                              final day = cityWeather.daily[dayIndex];
                              return _DailyTile(
                                label: day.label,
                                high: day.high,
                                low: day.low,
                                precipChance: day.precipChance,
                                compact: compactLayout,
                                unitLabel: day.unitLabel,
                                iconAsset: day.iconAsset,
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
                count: presentation.cities.length,
                index: presentation.selectedIndex,
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
              final settings = context.read<SettingsViewModel>().settings;
              final presentation = vm.toPresentation(settings, l10n);
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
                        initialItemCount: presentation.cities.length,
                        itemBuilder: (context, index, animation) {
                          final city = presentation.cities[index];
                          final displayName = city.displayName;

                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          );

                          return FadeTransition(
                            opacity: curved,
                            child: Dismissible(
                              key: ValueKey(city.id),
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
                                  removedName: displayName,
                                  animate: false,
                                );
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(displayName),
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
    String? removedName,
    bool animate = true,
  }) {
    if (index < 0 || index >= vm.cities.length) return;
    final removedCityName = removedName ?? vm.cities[index].city.name;

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
              removedCityName,
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
    required this.cityName,
    required this.conditionLabel,
    required this.temperature,
    required this.unitLabel,
    required this.iconAsset,
  });

  final String cityName;
  final String conditionLabel;
  final double temperature;
  final String unitLabel;
  final String iconAsset;

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
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      temperature.toStringAsFixed(1),
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
              _WeatherIcon(asset: iconAsset, size: 56),
            ],
          ),
          const SizedBox(height: 8),
          Text(conditionLabel, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _HourlyTile extends StatelessWidget {
  const _HourlyTile({
    required this.label,
    required this.temperature,
    required this.unitLabel,
    required this.iconAsset,
    this.precipChance,
  });

  final String label;
  final double temperature;
  final String iconAsset;
  final String unitLabel;
  final int? precipChance;

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
          _WeatherIcon(asset: iconAsset, size: iconSize),
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
    required this.iconAsset,
    this.precipChance,
    required this.compact,
    required this.unitLabel,
  });

  final String label;
  final double high;
  final double low;
  final String iconAsset;
  final int? precipChance;
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
          _WeatherIcon(asset: iconAsset, size: iconSize),
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
  const _WeatherIcon({required this.asset, this.size = 32});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
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

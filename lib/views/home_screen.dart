import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../viewmodels/weather_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Pittsburgh, PA coordinates
  final double _lat = 40.4406;
  final double _lon = -79.9959;

  Future<void> _load(BuildContext context) async {
    await Provider.of<WeatherViewModel>(context, listen: false)
        .fetchWeather(_lat, _lon);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(context),
          ),
        ],
      ),
      body: Consumer<WeatherViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (vm.error != null) {
            return Center(child: Text(vm.error!));
          } else if (vm.current == null || vm.hourly == null || vm.daily == null) {
            return const Center(child: Text('No weather data'));
          } else {
            final weather = vm.current!;
            final hourly = vm.hourly!;
            final daily = vm.daily!;

            return RefreshIndicator(
              onRefresh: () => _load(context),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CurrentConditionsCard(weather: weather),
                  const SizedBox(height: 24),
                  Text('Hourly', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: hourly.times.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _HourlyTile(
                          label: _formatHour(hourly.times[index]),
                          temperature: hourly.temperatures[index],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Daily', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: daily.times.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _DailyTile(
                        label: _formatDay(daily.times[index]),
                        high: daily.tempMax[index],
                        low: daily.tempMin[index],
                      );
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  String _formatHour(DateTime time) {
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
}

class _CurrentConditionsCard extends StatelessWidget {
  const _CurrentConditionsCard({required this.weather});

  final Weather weather;

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
          Text('Pittsburgh', style: theme.textTheme.titleMedium),
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
  const _HourlyTile({required this.label, required this.temperature});

  final String label;
  final double temperature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('${temperature.toStringAsFixed(0)}°',
              style: theme.textTheme.titleLarge),
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
  });

  final String label;
  final double high;
  final double low;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: theme.textTheme.bodyMedium)),
          const Spacer(),
          Text('${low.toStringAsFixed(0)}°', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Text('${high.toStringAsFixed(0)}°', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          final settings = vm.settings;
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Use a darker theme'),
                value: settings.darkMode,
                onChanged: vm.setDarkMode,
              ),
              SwitchListTile(
                title: const Text('Show temperatures in Celsius'),
                subtitle: const Text('Toggle between °F and °C'),
                value: settings.useCelsius,
                onChanged: vm.setUseCelsius,
              ),
              SwitchListTile(
                title: const Text('Compact layout'),
                subtitle: const Text('Reduce padding and card heights'),
                value: settings.compactLayout,
                onChanged: vm.setCompactLayout,
              ),
            ],
          );
        },
      ),
    );
  }
}

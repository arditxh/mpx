import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';


import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)), //AppBar(title: const Text('Settings')),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          final settings = vm.settings;
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              ListTile(
                title: Text(l10n.language),
                trailing: DropdownButton<String>(
                  //value: settings.languageCode, older version
                  value: (settings.languageCode == 'en' || settings.languageCode == 'es')
                      ? settings.languageCode
                      : 'en',
                  onChanged: (value) {
                    if (value != null) {
                      vm.setLanguage(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                  ],
                ),
              ),

              const Divider(),

              SwitchListTile(
                //title: const Text('Dark mode'),
                //subtitle: const Text('Use a darker theme'),
                title: Text(l10n.darkMode),
                subtitle: Text(l10n.darkModeSubtitle),
                value: settings.darkMode,
                onChanged: vm.setDarkMode,
              ),
              SwitchListTile(
                //title: const Text('Show temperatures in Celsius'),
                //subtitle: const Text('Toggle between °F and °C'),
                title: Text(l10n.useCelsius),
                subtitle: Text(l10n.useCelsiusSubtitle),
                value: settings.useCelsius,
                onChanged: vm.setUseCelsius,
              ),
              SwitchListTile(
                //title: const Text('Compact layout'),
                //subtitle: const Text('Reduce padding and card heights'),
                title: Text(l10n.compactLayout),
                subtitle: Text(l10n.compactLayoutSubtitle),
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

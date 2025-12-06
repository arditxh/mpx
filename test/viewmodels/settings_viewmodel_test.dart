import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/models/settings.dart';
import 'package:mpx/viewmodels/settings_viewmodel.dart';

import '../helpers/fakes.dart';

void main() {
  test('loads settings from repository', () async {
    final repo = FakeSettingsRepository(
      initial: const Settings(darkMode: true, useCelsius: true),
    );
    final vm = SettingsViewModel(repository: repo);

    await vm.load();

    expect(vm.settings.darkMode, isTrue);
    expect(vm.settings.useCelsius, isTrue);
  });

  test('updates toggles and persists', () async {
    final repo = FakeSettingsRepository();
    final vm = SettingsViewModel(repository: repo);

    await vm.load();
    await vm.setUseCelsius(true);
    await vm.setDarkMode(true);

    expect(vm.settings.useCelsius, isTrue);
    expect(vm.settings.darkMode, isTrue);

    final persisted = await repo.load();
    expect(persisted.useCelsius, isTrue);
    expect(persisted.darkMode, isTrue);
  });
}

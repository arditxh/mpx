import 'package:flutter/foundation.dart';

import '../models/settings.dart';
import '../repositories/settings_repository.dart';
import 'package:flutter/material.dart';


class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({SettingsRepository? repository})
      : _repository = repository ?? SharedPrefsSettingsRepository();

  final SettingsRepository _repository;
  //Locale get locale => Locale(_settings.languageCode); //older version
  Locale? get locale {
  if (_settings.languageCode.isEmpty) return null; 
  return Locale(_settings.languageCode);          
}


  Settings _settings = const Settings();
  bool _loading = false;

  Settings get settings => _settings;
  bool get isLoading => _loading;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    _settings = await _repository.load();
    _loading = false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) => _update(
        _settings.copyWith(darkMode: enabled),
      );

  Future<void> setUseCelsius(bool enabled) => _update(
        _settings.copyWith(useCelsius: enabled),
      );

  Future<void> setCompactLayout(bool enabled) => _update(
        _settings.copyWith(compactLayout: enabled),
      );

  Future<void> setLanguage(String languageCode) => _update(
      _settings.copyWith(languageCode: languageCode),
    );

  Future<void> setTextScale(double scale) {
    final clamped = scale.clamp(0.8, 1.6);
    return _update(
      _settings.copyWith(textScale: clamped.toDouble()),
    );
  }

  Future<void> _update(Settings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

abstract class SettingsRepository {
  Future<Settings> load();
  Future<void> save(Settings settings);
}

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _key = 'settings';

  final SharedPreferences? _preferences;

  @override
  Future<Settings> load() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const Settings();

    // Decode in a background isolate to avoid blocking UI if the payload grows.
    final parsed = await compute(_decodeSettings, raw);
    return parsed ?? const Settings();
  }

  @override
  Future<void> save(Settings settings) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = jsonEncode(settings.toJson());
    await prefs.setString(_key, raw);
  }
}

Settings? _decodeSettings(String raw) {
  try {
    final map = json.decode(raw) as Map<String, dynamic>;
    return Settings.fromJson(map);
  } catch (_) {
    return null;
  }
}

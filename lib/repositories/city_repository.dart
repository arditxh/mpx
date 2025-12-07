import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';

abstract class CityRepository {
  Future<List<City>> load();
  Future<void> save(List<City> cities);
}

class SharedPrefsCityRepository implements CityRepository {
  SharedPrefsCityRepository({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _key = 'cities';

  final SharedPreferences? _preferences;

  @override
  Future<List<City>> load() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];

    final parsed = await compute(_decodeCities, raw);
    return parsed ?? const [];
  }

  @override
  Future<void> save(List<City> cities) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = jsonEncode(cities.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

List<City>? _decodeCities(String raw) {
  try {
    final decoded = json.decode(raw);
    if (decoded is! List) return null;

    final cities = <City>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        try {
          cities.add(City.fromJson(item));
        } catch (_) {
          // Skip malformed entries.
        }
      } else if (item is Map) {
        try {
          cities.add(City.fromJson(item.cast<String, dynamic>()));
        } catch (_) {
          // Skip malformed entries.
        }
      }
    }
    return cities;
  } catch (_) {
    return null;
  }
}

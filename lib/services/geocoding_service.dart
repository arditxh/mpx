import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/city.dart';

class GeocodingService {
  static const _base = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<City?> searchCity(String name) async {
    final url = Uri.parse(_base).replace(queryParameters: {
      'name': name,
      'count': '1',
      'language': 'en',
      'format': 'json',
    });
    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    // Parse and map to City off the UI thread to avoid any JSON overhead on main isolate.
    return compute(
      _parseCityFromPayload,
      {'body': response.body, 'fallbackName': name},
    );
  }
}

City? _parseCityFromPayload(Map<String, String> payload) {
  final body = payload['body'];
  final fallbackName = payload['fallbackName'] ?? 'Unknown';
  if (body == null) return null;

  final data = json.decode(body) as Map<String, dynamic>;
  final results = data['results'] as List<dynamic>?;
  if (results == null || results.isEmpty) return null;

  final first = results.first as Map<String, dynamic>;
  return City(
    name: first['name'] as String? ?? fallbackName,
    latitude: (first['latitude'] as num).toDouble(),
    longitude: (first['longitude'] as num).toDouble(),
  );
}

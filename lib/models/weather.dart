class Weather {
  final double temperature;
  final String condition;
  final int code;
  final DateTime? time;

  Weather({required this.temperature, required this.condition, required this.code, this.time});

  factory Weather.fromJson(Map<String, dynamic> json) {
    final code = (json['weathercode'] ?? json['weather_code'] ?? 0) as int;
    return Weather(
      temperature: (json['temperature'] ?? 0).toDouble(),
      condition: _describe(code),
      code: code,
      time: _parseTime(json['time'] as String?),
    );
  }

  static DateTime? _parseTime(String? raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static String _describe(int code) {
    const descriptions = {
      0: 'Clear',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Fog',
      48: 'Depositing rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      56: 'Light freezing drizzle',
      57: 'Freezing drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      66: 'Light freezing rain',
      67: 'Freezing rain',
      71: 'Slight snow fall',
      73: 'Moderate snow fall',
      75: 'Heavy snow fall',
      77: 'Snow grains',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      85: 'Slight snow showers',
      86: 'Heavy snow showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with hail',
      99: 'Heavy thunderstorm with hail',
    };
    return descriptions[code] ?? 'Unknown';
  }
}

class HourlyModel {
  final List<DateTime> times;
  final List<double> temperatures;
  final List<int> codes;
  final List<int> precipitationProbability;

  HourlyModel({
    required this.times,
    required this.temperatures,
    required this.codes,
    required this.precipitationProbability,
  });

  factory HourlyModel.fromJson(Map<String, dynamic> json) {
    final hourly = json['hourly'];

    return HourlyModel(
      times: (hourly['time'] as List<dynamic>)
          .map((t) => DateTime.parse(t as String))
          .toList(),
      temperatures: (hourly['temperature_2m'] as List<dynamic>)
          .map((temp) => (temp as num).toDouble())
          .toList(),
      codes: (hourly['weathercode'] as List<dynamic>)
          .map((c) => (c as num).toInt())
          .toList(),
      precipitationProbability: (hourly['precipitation_probability'] as List<dynamic>? ?? [])
          .map((p) => (p as num?)?.toInt() ?? 0)
          .toList(),
    );
  }
}

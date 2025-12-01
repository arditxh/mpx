class DailyModel {
  final List<DateTime> times;
  final List<double> tempMax;
  final List<double> tempMin;
  final List<int> codes;
  final List<int> precipitationProbabilityMax;

  DailyModel({
    required this.times,
    required this.tempMax,
    required this.tempMin,
    required this.codes,
    required this.precipitationProbabilityMax,
  });

  factory DailyModel.fromJson(Map<String, dynamic> json) {
    return DailyModel(
      times: (json['time'] as List<dynamic>)
          .map((t) => DateTime.parse(t as String))
          .toList(),
      tempMax: (json['temperature_2m_max'] as List<dynamic>)
          .map((t) => (t as num).toDouble())
          .toList(),
      tempMin: (json['temperature_2m_min'] as List<dynamic>)
          .map((t) => (t as num).toDouble())
          .toList(),
      codes: (json['weathercode'] as List<dynamic>)
          .map((c) => (c as num).toInt())
          .toList(),
      precipitationProbabilityMax: (json['precipitation_probability_max'] as List<dynamic>? ?? [])
          .map((p) => (p as num?)?.toInt() ?? 0)
          .toList(),
    );
  }
}

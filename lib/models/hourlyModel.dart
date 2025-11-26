class HourlyModel {
  final List<DateTime> times;
  final List<double> temperatures;

  HourlyModel({
    required this.times,
    required this.temperatures,
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
    );
  }
}

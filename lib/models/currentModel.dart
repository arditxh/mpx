class CurrentModel {
  final DateTime time;
  final int interval;
  final double temperature;

  CurrentModel({
    required this.time,
    required this.interval,
    required this.temperature,
  });

  factory CurrentModel.fromJson(Map<String, dynamic> json) {
    return CurrentModel(
      time: DateTime.parse(json['time']),
      interval: json['interval'] as int,
      temperature: (json['temperature_2m'] as num).toDouble(),
    );
  }
}

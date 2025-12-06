class Settings {
  const Settings({
    this.darkMode = false,
    this.useCelsius = false,
    this.compactLayout = false,
  });

  final bool darkMode;
  final bool useCelsius;
  final bool compactLayout;

  Settings copyWith({
    bool? darkMode,
    bool? useCelsius,
    bool? compactLayout,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      useCelsius: useCelsius ?? this.useCelsius,
      compactLayout: compactLayout ?? this.compactLayout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'useCelsius': useCelsius,
      'compactLayout': compactLayout,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      darkMode: json['darkMode'] as bool? ?? false,
      useCelsius: json['useCelsius'] as bool? ?? false,
      compactLayout: json['compactLayout'] as bool? ?? false,
    );
  }
}

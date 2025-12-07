class Settings {
  const Settings({
    this.darkMode = false,
    this.useCelsius = false,
    this.compactLayout = false,
    this.languageCode = '', //en
  });

  final bool darkMode;
  final bool useCelsius;
  final bool compactLayout;
  final String languageCode; 
  
  Settings copyWith({
    bool? darkMode,
    bool? useCelsius,
    bool? compactLayout,
    String? languageCode,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      useCelsius: useCelsius ?? this.useCelsius,
      compactLayout: compactLayout ?? this.compactLayout,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'useCelsius': useCelsius,
      'compactLayout': compactLayout,
      'languageCode': languageCode, 
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      darkMode: json['darkMode'] as bool? ?? false,
      useCelsius: json['useCelsius'] as bool? ?? false,
      compactLayout: json['compactLayout'] as bool? ?? false,
      languageCode: json['languageCode'] as String? ?? '',
    );
  }
}

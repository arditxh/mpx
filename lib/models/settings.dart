class Settings {
  const Settings({
    this.darkMode = false,
    this.useCelsius = false,
    this.compactLayout = false,
    this.languageCode = '', //en
    this.textScale = 1.0,
  });

  final bool darkMode;
  final bool useCelsius;
  final bool compactLayout;
  final String languageCode; 
  final double textScale;
  
  Settings copyWith({
    bool? darkMode,
    bool? useCelsius,
    bool? compactLayout,
    String? languageCode,
    double? textScale,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      useCelsius: useCelsius ?? this.useCelsius,
      compactLayout: compactLayout ?? this.compactLayout,
      languageCode: languageCode ?? this.languageCode,
      textScale: textScale ?? this.textScale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'useCelsius': useCelsius,
      'compactLayout': compactLayout,
      'languageCode': languageCode, 
      'textScale': textScale,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    final rawScale = (json['textScale'] as num?)?.toDouble() ?? 1.0;
    final safeScale = rawScale.clamp(0.8, 1.6).toDouble();
    return Settings(
      darkMode: json['darkMode'] as bool? ?? false,
      useCelsius: json['useCelsius'] as bool? ?? false,
      compactLayout: json['compactLayout'] as bool? ?? false,
      languageCode: json['languageCode'] as String? ?? '',
      textScale: safeScale,
    );
  }
}

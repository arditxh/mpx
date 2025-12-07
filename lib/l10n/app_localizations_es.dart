// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aplicación del Clima';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get useMetric => 'Usar unidades métricas';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Algo salió mal';

  @override
  String get noData => 'No hay datos disponibles';

  @override
  String get currentWeather => 'Clima actual';

  @override
  String get dailyForecast => 'Pronóstico diario';

  @override
  String get hourly => 'Por hora';

  @override
  String get addCity => 'Agregar ciudad';

  @override
  String get useMyLocation => 'Usar mi ubicación';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Agregar';

  @override
  String get addRemoveCity => 'Agregar / Eliminar ciudad';

  @override
  String get textSize => 'Tamaño de texto';

  @override
  String get textSizeSubtitle => 'Ajusta el tamaño del texto de la app para mayor legibilidad';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get darkModeSubtitle => 'Usar un tema oscuro';

  @override
  String get useCelsius => 'Mostrar temperaturas en Celsius';

  @override
  String get useCelsiusSubtitle => 'Cambiar entre °F y °C';

  @override
  String get compactLayout => 'Diseño compacto';

  @override
  String get compactLayoutSubtitle => 'Reducir el espacio y el tamaño de las tarjetas';

  @override
  String get enterCityName => 'Ingrese el nombre de la ciudad';

  @override
  String get currentCities => 'Ciudades actuales';

  @override
  String get swipeToDelete => 'Desliza a la derecha para eliminar';

  @override
  String get delete => 'Eliminar';
}

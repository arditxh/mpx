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
  String get today => 'Hoy';

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

  @override
  String get now => 'Ahora';

  @override
  String get currentLocation => 'Ubicación actual';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get enableLocationSettingsHint => 'Habilita el acceso a la ubicación en la configuración del sistema.';

  @override
  String get cityRestorePartial => 'Algunas ciudades guardadas no se pudieron restaurar. Desliza para actualizar.';

  @override
  String get loadSavedCitiesFailed => 'No se pudieron cargar las ciudades guardadas.';

  @override
  String get cityNotFound => 'Ciudad no encontrada';

  @override
  String get failedToAddCity => 'No se pudo agregar la ciudad.';

  @override
  String failedToRefreshCity(Object city) {
    return 'No se pudo actualizar $city.';
  }

  @override
  String get cityAlreadyAdded => 'Ciudad ya agregada';

  @override
  String weatherUnavailable(Object city) {
    return 'Datos del clima no disponibles para $city.';
  }

  @override
  String networkIssueForCity(Object city) {
    return 'Problema de red al obtener $city. Verifica tu conexión.';
  }

  @override
  String unexpectedResponseForCity(Object city) {
    return 'Respuesta inesperada para el clima de $city. Inténtalo de nuevo.';
  }

  @override
  String parsingErrorForCity(Object city) {
    return 'No se pudieron leer los datos del clima de $city. Inténtalo más tarde.';
  }

  @override
  String get locationServiceDisabled => 'Activa los servicios de ubicación para ver el clima local.';

  @override
  String get locationPermissionDenied => 'Permiso de ubicación denegado. Habilita el acceso y actualiza.';

  @override
  String get locationPermissionPermanentlyDenied => 'Permiso de ubicación denegado permanentemente. Habilítalo en la configuración del sistema.';

  @override
  String get locationTimeout => 'Se agotó el tiempo al obtener tu ubicación. Desliza para actualizar e inténtalo de nuevo.';

  @override
  String get locationUnavailable => 'Ubicación no disponible en este momento. Desliza para reintentar.';

  @override
  String locationFallbackMessage(Object city, Object message) {
    return '$message Mostrando $city. Habilita la ubicación y actualiza.';
  }

  @override
  String get weatherClear => 'Despejado';

  @override
  String get weatherMainlyClear => 'Mayormente despejado';

  @override
  String get weatherPartlyCloudy => 'Parcialmente nublado';

  @override
  String get weatherOvercast => 'Nublado';

  @override
  String get weatherFog => 'Niebla';

  @override
  String get weatherRimeFog => 'Niebla con escarcha';

  @override
  String get weatherLightDrizzle => 'Llovizna ligera';

  @override
  String get weatherModerateDrizzle => 'Llovizna moderada';

  @override
  String get weatherDenseDrizzle => 'Llovizna intensa';

  @override
  String get weatherLightFreezingDrizzle => 'Llovizna helada ligera';

  @override
  String get weatherFreezingDrizzle => 'Llovizna helada';

  @override
  String get weatherSlightRain => 'Lluvia leve';

  @override
  String get weatherModerateRain => 'Lluvia moderada';

  @override
  String get weatherHeavyRain => 'Lluvia intensa';

  @override
  String get weatherLightFreezingRain => 'Lluvia helada ligera';

  @override
  String get weatherFreezingRain => 'Lluvia helada';

  @override
  String get weatherSlightSnowFall => 'Nevada ligera';

  @override
  String get weatherModerateSnowFall => 'Nevada moderada';

  @override
  String get weatherHeavySnowFall => 'Nevada intensa';

  @override
  String get weatherSnowGrains => 'Granos de nieve';

  @override
  String get weatherSlightRainShowers => 'Chubascos ligeros';

  @override
  String get weatherModerateRainShowers => 'Chubascos moderados';

  @override
  String get weatherViolentRainShowers => 'Chubascos fuertes';

  @override
  String get weatherSlightSnowShowers => 'Chubascos de nieve ligeros';

  @override
  String get weatherHeavySnowShowers => 'Chubascos de nieve intensos';

  @override
  String get weatherThunderstorm => 'Tormenta eléctrica';

  @override
  String get weatherThunderstormWithHail => 'Tormenta eléctrica con granizo';

  @override
  String get weatherHeavyThunderstormWithHail => 'Tormenta eléctrica fuerte con granizo';
}

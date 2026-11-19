import 'package:flutter/widgets.dart';
import '../settings/app_settings_scope.dart';

/// Textos localizados ligeros (Español / English) para navegación y configuración.
class AppStrings {
  final bool isEn;

  const AppStrings._(this.isEn);

  factory AppStrings.fromCode(String? code) {
    return AppStrings._((code ?? '').trim().toLowerCase() == 'en');
  }

  static AppStrings of(BuildContext context) {
    return AppStrings.fromCode(AppSettingsScope.of(context).languageCode);
  }

  // Navegación principal
  String get navHistory => isEn ? 'History' : 'Historial';
  String get navWorkouts => isEn ? 'Workouts' : 'Rutinas';
  String get navProfile => isEn ? 'Profile' : 'Perfil';
  String get workoutHistoryTitle =>
      isEn ? 'Workout History' : 'Historial de entrenamientos';
  String get settingsTooltip => isEn ? 'Settings' : 'Configuración';
  String get logoutTooltip => isEn ? 'Log out' : 'Cerrar sesión';

  // Diálogo cerrar sesión
  String get logoutTitle => isEn ? 'Log out?' : '¿Cerrar sesión?';
  String get logoutMessage => isEn
      ? 'Are you sure you want to log out?'
      : '¿Seguro que quieres cerrar sesión?';
  String get cancel => isEn ? 'Cancel' : 'Cancelar';
  String get logOut => isEn ? 'Log out' : 'Cerrar sesión';

  // Perfil
  String get editProfile => isEn ? 'Edit profile' : 'Editar perfil';
  String get settings => isEn ? 'Settings' : 'Configuración';
  String get publicProfileLabel => isEn ? 'Public profile' : 'Perfil público';
  String get privateProfileLabel =>
      isEn ? 'Private profile' : 'Perfil privado';
  String get hiddenStatsLabel =>
      isEn ? 'Stats hidden' : 'Estadísticas ocultas';

  // Pantalla de configuración — cabecera y secciones
  String get settingsTitle => isEn ? 'Settings' : 'Configuración';
  String get sectionAppearance =>
      isEn ? 'Appearance & Theme' : 'Apariencia y tema';
  String get sectionPrivacy =>
      isEn ? 'Privacy & Visibility' : 'Privacidad y visibilidad del perfil';
  String get sectionLanguageUnits =>
      isEn ? 'Language & Units' : 'Idioma y unidades';
  String get sectionTrainingTimer =>
      isEn ? 'Workout & Rest Timer' : 'Entrenamiento y temporizador';
  String get sectionAccountSecurity =>
      isEn ? 'Data, Security & Account' : 'Datos, seguridad y cuenta';

  // Tema
  String get themeLabel => isEn ? 'App theme' : 'Tema de la aplicación';
  String get themeLight => isEn ? 'Light' : 'Claro';
  String get themeDark => isEn ? 'Dark' : 'Oscuro';
  String get themeSystem => isEn ? 'System' : 'Sistema';

  // Privacidad
  String get publicAccountTitle => isEn ? 'Public account' : 'Cuenta pública';
  String get publicAccountSubtitle => isEn
      ? 'Allow other athletes to discover and view your profile'
      : 'Permite que otros usuarios encuentren y vean tu perfil';
  String get showDobTitle =>
      isEn ? 'Show birth date / age' : 'Mostrar fecha de nacimiento';
  String get showDobSubtitle => isEn
      ? 'Display your birth date on your profile view'
      : 'Hace visible tu fecha de nacimiento en tu perfil';
  String get showStatsTitle =>
      isEn ? 'Show global statistics' : 'Mostrar estadísticas globales';
  String get showStatsSubtitle => isEn
      ? 'Share volume, streak and muscle activity with others'
      : 'Muestra volumen, racha y actividad en el perfil social';
  String get showRoutinesTitle =>
      isEn ? 'Show public routines' : 'Mostrar rutinas públicas';
  String get showRoutinesSubtitle => isEn
      ? 'Allow others to browse your saved routines'
      : 'Permite que otros vean tus rutinas guardadas';
  String get editPersonalData =>
      isEn ? 'Edit personal data' : 'Editar datos personales';
  String get editPersonalDataSubtitle => isEn
      ? 'Name, surname, birth date'
      : 'Nombre, apellidos y fecha de nacimiento';
  String get offlinePrivacyHint => isEn
      ? 'Sign in or check connection to sync profile privacy.'
      : 'No se pudo cargar el perfil del servidor. Pulsa reintentar para editar privacidad.';
  String get retry => isEn ? 'Retry' : 'Reintentar';

  // Idioma y unidades
  String get languageLabel => isEn ? 'Language' : 'Idioma';
  String get weightUnitLabel => isEn ? 'Weight unit' : 'Unidad de peso';

  // Entrenamiento y temporizador
  String get defaultRestTitle =>
      isEn ? 'Default rest time' : 'Descanso predeterminado';
  String get defaultRestSubtitle => isEn
      ? 'Applied when adding new exercises'
      : 'Se aplica al añadir ejercicios nuevos';
  String get restSoundTitle => isEn ? 'Subtle sound alert' : 'Alerta sonora sutil';
  String get restSoundSubtitle => isEn
      ? 'Gentle tone when rest timer ends without cutting music'
      : 'Tono suave al terminar el descanso sin cortar tu música';
  String get restVibrationTitle =>
      isEn ? 'Timer vibration' : 'Vibración del temporizador';
  String get restVibrationSubtitle => isEn
      ? 'Vibrate when rest interval finishes'
      : 'Vibra cuando finaliza el tiempo de descanso';
  String get restNotificationTitle =>
      isEn ? 'Interactive notification' : 'Notificación interactiva';
  String get restNotificationSubtitle => isEn
      ? 'Live countdown with -20s / +20s / Stop controls'
      : 'Cuenta atrás en vivo con controles -20s / +20s / Terminar';
  String get keepScreenOnTitle =>
      isEn ? 'Keep screen awake' : 'Mantener pantalla encendida';
  String get keepScreenOnSubtitle => isEn
      ? 'Prevent screen sleep during an active workout'
      : 'Evita que se apague la pantalla durante una sesión activa';
  String get hapticSetTitle =>
      isEn ? 'Haptic feedback on set complete' : 'Vibración al completar serie';
  String get hapticSetSubtitle => isEn
      ? 'Tactile pulse when marking a set as completed'
      : 'Respuesta háptica al marcar una serie como completada';

  // Datos, seguridad y cuenta
  String get changePasswordTitle =>
      isEn ? 'Change password' : 'Cambiar contraseña';
  String get changePasswordSubtitle => isEn
      ? 'Verify your current password and set a new one'
      : 'Verifica tu contraseña actual y establece una nueva';
  String get exportHistoryTitle =>
      isEn ? 'Export workout history' : 'Exportar historial';
  String get exportHistorySubtitle => isEn
      ? 'Download or copy all sessions in CSV or JSON'
      : 'Genera y comparte todos tus entrenamientos en CSV o JSON';
  String get dangerZoneTitle => isEn ? 'Danger zone' : 'Zona de peligro';
  String get deleteAccountTitle =>
      isEn ? 'Delete account permanently' : 'Eliminar cuenta definitivamente';
  String get deleteAccountSubtitle => isEn
      ? 'Permanently erase your user, workouts and routines'
      : 'Borra de forma irreversible tu usuario, entrenamientos y rutinas';
  String get deleteConfirmKeyword => isEn ? 'DELETE' : 'ELIMINAR';
}

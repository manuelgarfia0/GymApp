import 'package:flutter/foundation.dart';

/// Constantes de red de la API.
///
/// La URL base se configura en tiempo de compilación con --dart-define:
///
/// Emulador Android:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
///
/// Dispositivo físico (ajusta la IP de tu PC):
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.XX:8080/api
///
/// Si no se especifica:
/// - En Web o Desktop (Windows/macOS/Linux) usa 'http://localhost:8080/api'
/// - En móvil (Android emulador) usa 'http://10.0.2.2:8080/api'
class ApiConstants {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    // En navegador web o en aplicaciones de escritorio, el backend local está en localhost
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:8080/api';
    }

    // Para emulador Android por defecto
    return 'http://10.0.2.2:8080/api';
  }

  // Auth
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get currentUserEndpoint => '$baseUrl/auth/me';

  // Workouts
  static String get exercisesEndpoint => '$baseUrl/exercises';
  static String get routinesEndpoint => '$baseUrl/routines';
  static String get workoutsEndpoint => '$baseUrl/workouts';

  // Profile
  static String get usersEndpoint => '$baseUrl/users';
}

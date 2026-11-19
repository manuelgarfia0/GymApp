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
/// - En Android resuelve automáticamente en orden:
///   1. 'http://localhost:8080/api' (con `adb reverse tcp:8080 tcp:8080`)
///   2. 'http://192.168.0.147:8080/api' (IP local del PC en la red LAN/Wi-Fi)
///   3. 'http://10.0.2.2:8080/api' (emulador Android)
class ApiConstants {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String _localApiBaseUrl = 'http://localhost:8080/api';
  static const String _lanApiBaseUrl = 'http://192.168.0.147:8080/api';
  static const String _emulatorApiBaseUrl = 'http://10.0.2.2:8080/api';

  /// Candidatos de conexión para Android cuando no se pasa `--dart-define=API_BASE_URL`.
  static const List<String> androidFallbackBaseUrls = [
    _localApiBaseUrl,
    _lanApiBaseUrl,
    _emulatorApiBaseUrl,
  ];

  static String? _resolvedAndroidBaseUrl;

  static bool get hasExplicitBaseUrl => _envBaseUrl.isNotEmpty;

  static bool get hasResolvedBaseUrl =>
      hasExplicitBaseUrl || _resolvedAndroidBaseUrl != null;

  static bool get isUsingAndroidFallback =>
      !hasExplicitBaseUrl &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  static void setResolvedBaseUrl(String url) {
    _resolvedAndroidBaseUrl = url;
  }

  static void resetResolvedBaseUrl() {
    _resolvedAndroidBaseUrl = null;
  }

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_envBaseUrl);
    }

    // En navegador web o en aplicaciones de escritorio, el backend local está en localhost
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return _localApiBaseUrl;
    }

    // En Android usa la URL ya resuelta o localhost como primer candidato de sonda
    return _resolvedAndroidBaseUrl ?? androidFallbackBaseUrls.first;
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return _localApiBaseUrl;
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  // Health / Warm-up
  static String get pingEndpoint => '$baseUrl/ping';

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

/// Constantes de red de la API.
///
/// La URL base se configura en tiempo de compilación con --dart-define:
///
/// Emulador Android:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
///
/// Dispositivo físico (ajusta la IP de tu PC):
///   flutter run --dart-define=API_BASE_URL=http://10.0.1.91:8080/api
///
/// Si no se especifica, usa la URL del emulador por defecto.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  // Auth
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String registerEndpoint = '$baseUrl/auth/register';
  static const String currentUserEndpoint = '$baseUrl/auth/me';

  // Workouts
  static const String exercisesEndpoint = '$baseUrl/exercises';
  static const String routinesEndpoint = '$baseUrl/routines';
  static const String workoutsEndpoint = '$baseUrl/workouts';

  // Profile
  static const String usersEndpoint = '$baseUrl/users';
}

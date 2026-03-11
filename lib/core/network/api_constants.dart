// Archivo: lib/core/network/api_constants.dart

class ApiConstants {
  // URL base: Usamos 10.0.2.2 para el emulador de Android apuntando a tu PC
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Endpoints específicos de Autenticación
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String registerEndpoint = '$baseUrl/auth/register';
  static const String currentUserEndpoint = '$baseUrl/auth/me';

  // Endpoints específicos de Workouts
  static const String exercisesEndpoint = '$baseUrl/exercises';
  static const String routinesEndpoint = '$baseUrl/routines';
  static const String workoutsEndpoint = '$baseUrl/workouts';

  // Endpoints específicos de Profile
  static const String usersEndpoint = '$baseUrl/users';
}

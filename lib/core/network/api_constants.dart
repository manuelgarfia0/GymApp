// Archivo: lib/core/network/api_constants.dart

class ApiConstants {
  // URL base: Usamos 10.0.2.2 para el emulador de Android apuntando a tu PC
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  
  // Endpoints específicos de Autenticación
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String registerEndpoint = '$baseUrl/auth/register';

  // En el futuro puedes añadir más aquí:
  // static const String workoutsEndpoint = '$baseUrl/workouts';
}
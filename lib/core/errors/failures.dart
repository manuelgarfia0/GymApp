/// Clase base para todos los fallos de dominio
///
/// Los fallos representan violaciones de reglas de negocio o errores de sistemas externos
/// que deben ser manejados de manera elegante por la capa de presentación.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode ^ runtimeType.hashCode;

  @override
  String toString() => '$runtimeType: $message';
}

/// Fallo relacionado con autenticación y autorización
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);

  /// Instancias comunes de fallos de autenticación
  static const invalidCredentials = AuthenticationFailure(
    'Invalid username or password',
  );
  static const tokenExpired = AuthenticationFailure(
    'Session expired, please login again',
  );
  static const unauthorized = AuthenticationFailure(
    'You are not authorized to perform this action',
  );
  static const accountLocked = AuthenticationFailure(
    'Account is locked, please contact support',
  );
}

/// Fallo relacionado con conectividad de red y comunicación con el servidor
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);

  /// Instancias comunes de fallos de red
  static const noConnection = NetworkFailure(
    'No internet connection available',
  );
  static const serverError = NetworkFailure(
    'Server error, please try again later',
  );
  static const timeout = NetworkFailure(
    'Request timed out, please check your connection',
  );
  static const badRequest = NetworkFailure('Invalid request format');
  static const notFound = NetworkFailure('Requested resource not found');
}

/// Fallo relacionado con validación de entrada y violaciones de reglas de negocio
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);

  /// Instancias comunes de fallos de validación
  static const emptyUsername = ValidationFailure('Username cannot be empty');
  static const emptyPassword = ValidationFailure('Password cannot be empty');
  static const invalidEmail = ValidationFailure(
    'Please enter a valid email address',
  );
  static const passwordTooShort = ValidationFailure(
    'Password must be at least 8 characters',
  );
  static const invalidWeight = ValidationFailure(
    'Weight must be a positive number',
  );
  static const invalidReps = ValidationFailure(
    'Reps must be a positive integer',
  );
}

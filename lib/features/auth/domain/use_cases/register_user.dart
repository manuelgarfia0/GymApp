import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para el registro de nuevos usuarios.
/// Encapsula la validación y lógica de negocio del registro.
class RegisterUser {
  final AuthRepository _repository;

  const RegisterUser(this._repository);

  /// Registra un nuevo usuario y devuelve su entidad de dominio.
  /// Lanza [ValidationFailure] con mensaje descriptivo si la validación falla.
  Future<User> call(
    String username,
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? languagePreference,
  }) async {
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();
    final cleanFirstName = firstName?.trim();
    final cleanLastName = lastName?.trim();
    final cleanDateOfBirth = dateOfBirth?.trim();
    final cleanLanguage = languagePreference?.trim().toLowerCase();

    if (cleanUsername.isEmpty) {
      throw const ValidationFailure('El nombre de usuario no puede estar vacío');
    }

    if (cleanUsername.length < 3) {
      throw const ValidationFailure('El nombre de usuario debe tener al menos 3 caracteres');
    }

    if (cleanEmail.isEmpty) {
      throw const ValidationFailure('El correo electrónico no puede estar vacío');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const ValidationFailure('Introduce un correo electrónico válido (ej. usuario@correo.com)');
    }

    if (password.isEmpty) {
      throw const ValidationFailure('La contraseña no puede estar vacía');
    }

    if (password.length < 8) {
      throw const ValidationFailure('La contraseña debe tener al menos 8 caracteres');
    }

    await _repository.register(
      cleanUsername,
      cleanEmail,
      password,
      firstName: cleanFirstName,
      lastName: cleanLastName,
      dateOfBirth: cleanDateOfBirth,
      languagePreference: cleanLanguage,
    );

    final user = await _repository.getCurrentUser();

    if (user == null) {
      throw const AuthenticationFailure('No se pudo recuperar la información del usuario tras el registro');
    }

    return user;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

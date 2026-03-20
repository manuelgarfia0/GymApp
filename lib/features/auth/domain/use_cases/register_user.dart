import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para el registro de nuevos usuarios.
/// Encapsula la validación y lógica de negocio del registro.
class RegisterUser {
  final AuthRepository _repository;

  const RegisterUser(this._repository);

  /// Registra un nuevo usuario y devuelve su entidad de dominio.
  /// Lanza excepción con mensaje descriptivo si la validación o el registro fallan.
  Future<User> call(String username, String email, String password) async {
    if (username.trim().isEmpty) {
      throw Exception('Username cannot be empty');
    }

    if (email.trim().isEmpty) {
      throw Exception('Email cannot be empty');
    }

    if (password.trim().isEmpty) {
      throw Exception('Password cannot be empty');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    // CORRECCIÓN: el backend exige mínimo 8 caracteres (@Size(min = 8) en UserRegistrationDTO)
    // El valor anterior de 6 causaba que la validación pasara en Flutter
    // pero el backend rechazara la petición con 400 Bad Request.
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    await _repository.register(username, email, password);

    final user = await _repository.getCurrentUser();

    if (user == null) {
      throw Exception('Failed to retrieve user information after registration');
    }

    return user;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
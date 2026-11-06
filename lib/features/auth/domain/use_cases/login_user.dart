import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para el inicio de sesión.
/// Encapsula la validación y lógica de negocio para autenticar un usuario.
class LoginUser {
  final AuthRepository _repository;

  const LoginUser(this._repository);

  /// Ejecuta el caso de uso de login.
  /// Devuelve el [User] autenticado en caso de éxito.
  /// Lanza [Failure] con mensaje descriptivo si falla.
  Future<User> call(String username, String password) async {
    final cleanUsername = username.trim();

    if (cleanUsername.isEmpty) {
      throw const ValidationFailure('Introduce tu nombre de usuario o correo electrónico');
    }

    if (password.isEmpty) {
      throw const ValidationFailure('Introduce tu contraseña');
    }

    await _repository.login(cleanUsername, password);

    final user = await _repository.getCurrentUser();

    if (user == null) {
      throw const AuthenticationFailure('No se pudo recuperar la información del usuario tras iniciar sesión');
    }

    return user;
  }
}

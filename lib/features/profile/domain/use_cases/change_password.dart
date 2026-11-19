import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para cambiar la contraseña validando la actual.
class ChangePassword {
  final ProfileRepository repository;

  const ChangePassword(this.repository);

  Future<void> call({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (userId <= 0) {
      throw const ValidationFailure('Se requiere un ID de usuario válido');
    }
    if (currentPassword.isEmpty) {
      throw const ValidationFailure('Introduce tu contraseña actual');
    }
    if (newPassword.length < 6) {
      throw const ValidationFailure(
        'La nueva contraseña debe tener al menos 6 caracteres',
      );
    }
    if (currentPassword == newPassword) {
      throw const ValidationFailure(
        'La nueva contraseña debe ser diferente a la actual',
      );
    }
    await repository.changePassword(userId, currentPassword, newPassword);
  }
}

import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para eliminar definitivamente la cuenta del usuario autenticado.
class DeleteAccount {
  final ProfileRepository repository;

  const DeleteAccount(this.repository);

  Future<void> call({required int userId, required String password}) async {
    if (userId <= 0) {
      throw const ValidationFailure('Se requiere un ID de usuario válido');
    }
    if (password.isEmpty) {
      throw const ValidationFailure(
        'Introduce tu contraseña para confirmar la eliminación',
      );
    }
    await repository.deleteAccount(userId, password);
  }
}

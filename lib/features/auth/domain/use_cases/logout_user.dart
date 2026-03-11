import '../repositories/auth_repository.dart';

/// Use case for user logout
/// Handles the business logic for logging out a user
class LogoutUser {
  final AuthRepository _repository;

  const LogoutUser(this._repository);

  /// Executes the logout use case
  /// Clears stored authentication token and user session
  Future<void> call() async {
    await _repository.logout();
  }
}

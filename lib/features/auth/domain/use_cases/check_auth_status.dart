import '../repositories/auth_repository.dart';

/// Use case for checking authentication status
/// Handles the business logic for determining if user is logged in
class CheckAuthStatus {
  final AuthRepository _repository;

  const CheckAuthStatus(this._repository);

  /// Executes the check authentication status use case
  /// Returns true if user is authenticated, false otherwise
  Future<bool> call() async {
    return await _repository.isLoggedIn();
  }
}

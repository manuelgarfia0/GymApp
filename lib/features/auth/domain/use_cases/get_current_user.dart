import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for retrieving the current authenticated user
/// Handles the business logic for getting user information
class GetCurrentUser {
  final AuthRepository _repository;

  const GetCurrentUser(this._repository);

  /// Executes the get current user use case
  /// Returns the current User if authenticated, null otherwise
  Future<User?> call() async {
    return await _repository.getCurrentUser();
  }
}

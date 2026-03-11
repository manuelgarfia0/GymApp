import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
/// Handles the business logic for authenticating a user
class LoginUser {
  final AuthRepository _repository;

  const LoginUser(this._repository);

  /// Executes the login use case
  /// Returns the authenticated User on success
  /// Throws exception on authentication failure
  Future<User> call(String username, String password) async {
    // Validate input parameters
    if (username.trim().isEmpty) {
      throw Exception('Username cannot be empty');
    }

    if (password.trim().isEmpty) {
      throw Exception('Password cannot be empty');
    }

    // Perform login through repository
    await _repository.login(username, password);

    // Get the current user after successful login
    final user = await _repository.getCurrentUser();

    if (user == null) {
      throw Exception('Failed to retrieve user information after login');
    }

    return user;
  }
}

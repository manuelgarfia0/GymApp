import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration
/// Handles the business logic for creating a new user account
class RegisterUser {
  final AuthRepository _repository;

  const RegisterUser(this._repository);

  /// Executes the registration use case
  /// Returns the newly created User on success
  /// Throws exception on registration failure
  Future<User> call(String username, String email, String password) async {
    // Validate input parameters
    if (username.trim().isEmpty) {
      throw Exception('Username cannot be empty');
    }

    if (email.trim().isEmpty) {
      throw Exception('Email cannot be empty');
    }

    if (password.trim().isEmpty) {
      throw Exception('Password cannot be empty');
    }

    // Basic email validation
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    // Basic password validation
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    // Perform registration through repository
    await _repository.register(username, email, password);

    // Get the current user after successful registration
    final user = await _repository.getCurrentUser();

    if (user == null) {
      throw Exception('Failed to retrieve user information after registration');
    }

    return user;
  }

  /// Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

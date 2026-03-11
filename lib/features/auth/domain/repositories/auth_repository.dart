import '../entities/user.dart';

// Repository interface for authentication operations
// This defines the contract that data layer implementations must fulfill
abstract class AuthRepository {
  /// Authenticates user with username and password
  /// Returns JWT token on successful authentication
  /// Throws exception on authentication failure
  Future<String> login(String username, String password);

  /// Registers a new user account
  /// Returns JWT token on successful registration
  /// Throws exception on registration failure
  Future<String> register(String username, String email, String password);

  /// Logs out the current user
  /// Clears stored authentication token
  Future<void> logout();

  /// Retrieves the currently authenticated user
  /// Returns null if no user is authenticated
  Future<User?> getCurrentUser();

  /// Checks if a user is currently logged in
  /// Returns true if valid token exists, false otherwise
  Future<bool> isLoggedIn();

  /// Gets the stored JWT token
  /// Returns null if no token is stored
  Future<String?> getToken();
}

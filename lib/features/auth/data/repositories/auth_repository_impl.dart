import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository that bridges datasource and domain
/// Handles JWT token storage and transforms DTOs to entities
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final SecureStorageService storageService;

  const AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.storageService,
  });

  @override
  Future<String> login(String username, String password) async {
    try {
      // Validate input
      if (username.trim().isEmpty) {
        throw const ValidationFailure('Username cannot be empty');
      }
      if (password.trim().isEmpty) {
        throw const ValidationFailure('Password cannot be empty');
      }

      // Get token from remote datasource
      final token = await remoteDatasource.login(username, password);

      // Store token securely
      await storageService.saveToken(token);

      return token;
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an HTTP error with status code
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure('Invalid username or password');
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'Account is locked, please contact support',
        );
      } else if (errorMessage.contains('404')) {
        throw const NetworkFailure(
          'Service not available, please try again later',
        );
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<String> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      // Validate input
      if (username.trim().isEmpty) {
        throw const ValidationFailure('Username cannot be empty');
      }
      if (email.trim().isEmpty) {
        throw const ValidationFailure('Email cannot be empty');
      }
      if (password.trim().isEmpty) {
        throw const ValidationFailure('Password cannot be empty');
      }
      if (password.length < 8) {
        throw const ValidationFailure('Password must be at least 8 characters');
      }
      // Basic email validation
      if (!email.contains('@') || !email.contains('.')) {
        throw const ValidationFailure('Please enter a valid email address');
      }

      // Get token from remote datasource
      final token = await remoteDatasource.register(username, email, password);

      // Store token securely
      await storageService.saveToken(token);

      return token;
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an HTTP error with status code
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('409') || errorMessage.contains('conflict')) {
        throw const AuthenticationFailure('Username or email already exists');
      } else if (errorMessage.contains('400') ||
          errorMessage.contains('bad request')) {
        throw const ValidationFailure('Invalid registration data provided');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Clear stored token
      await storageService.deleteToken();
    } catch (e) {
      // Even if storage fails, we should complete logout
      // Log error but don't throw to prevent logout issues
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Check if token exists
      final token = await storageService.readToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Get user data from remote datasource
      final userDto = await remoteDatasource.getCurrentUser();

      // Transform DTO to entity before returning to domain layer
      return userDto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        // Token is invalid, clear it and return null
        await storageService.deleteToken();
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // For other errors, clear token and return null (graceful degradation)
      await storageService.deleteToken();
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await storageService.readToken();

      // Basic check - token exists and is not empty
      if (token == null || token.isEmpty) {
        return false;
      }

      // Try to get current user to validate token
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      // If any error occurs, consider user not logged in
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await storageService.readToken();
    } catch (e) {
      // If storage fails, return null
      return null;
    }
  }
}

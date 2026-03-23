// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación del repositorio de autenticación.
///
/// Responsabilidades:
/// - Delegar las operaciones de red al [AuthRemoteDatasource].
/// - Persistir/eliminar el token JWT en [SecureStorageService].
/// - Mapear excepciones de infraestructura a [Failure] de dominio.
///
/// El userId se extrae del propio JWT cuando es necesario,
/// eliminando la dependencia de [SharedPreferences] como almacén
/// secundario y evitando posibles desincronizaciones.
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
      _validateCredentials(username, password);

      final token = await remoteDatasource.login(username, password);
      await storageService.saveToken(token);

      return token;
    } on ServerException catch (e) {
      throw _mapServerException(e);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapLegacyError(e, 'Login failed');
    }
  }

  @override
  Future<String> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      _validateRegistration(username, email, password);

      final token = await remoteDatasource.register(username, email, password);
      await storageService.saveToken(token);

      return token;
    } on ServerException catch (e) {
      throw _mapServerException(e);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapLegacyError(e, 'Registration failed');
    }
  }

  @override
  Future<void> logout() async {
    // El token JWT es la única fuente de sesión — basta con eliminarlo.
    await storageService.deleteToken();
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final token = await storageService.readToken();
      if (token == null || token.isEmpty) return null;

      final userDto = await remoteDatasource.getCurrentUser();
      return userDto.toEntity();
    } on ServerException catch (e) {
      if (e.type == ServerErrorType.authentication) {
        await storageService.deleteToken();
        throw AuthenticationFailure(e.message);
      }
      throw _mapServerException(e);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        await storageService.deleteToken();
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      }
      await storageService.deleteToken();
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await storageService.readToken();
      if (token == null || token.isEmpty) return false;

      if (JwtDecoder.isExpired(token)) {
        await storageService.deleteToken();
        return false;
      }

      final user = await getCurrentUser();
      return user != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await storageService.readToken();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Validación
  // ---------------------------------------------------------------------------

  void _validateCredentials(String username, String password) {
    if (username.trim().isEmpty) {
      throw const ValidationFailure('Username cannot be empty');
    }
    if (password.trim().isEmpty) {
      throw const ValidationFailure('Password cannot be empty');
    }
  }

  void _validateRegistration(String username, String email, String password) {
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
    if (!email.contains('@') || !email.contains('.')) {
      throw const ValidationFailure('Please enter a valid email address');
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de errores
  // ---------------------------------------------------------------------------

  Failure _mapServerException(ServerException e) {
    switch (e.type) {
      case ServerErrorType.authentication:
      case ServerErrorType.forbidden:
        return AuthenticationFailure(e.message);
      case ServerErrorType.conflict:
        return ValidationFailure(e.message);
      case ServerErrorType.validationError:
        return ValidationFailure(e.message);
      default:
        return NetworkFailure(e.message);
    }
  }

  Failure _mapLegacyError(Object e, String prefix) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('invalid credentials')) {
      return const AuthenticationFailure('Invalid username or password');
    } else if (msg.contains('403') || msg.contains('forbidden')) {
      return const AuthenticationFailure(
        'Account is locked, please contact support',
      );
    } else if (msg.contains('409') || msg.contains('conflict')) {
      return const ValidationFailure('Username or email already exists');
    } else if (msg.contains('500') || msg.contains('server')) {
      return const NetworkFailure('Server error, please try again later');
    }
    return NetworkFailure('$prefix: ${e.toString()}');
  }
}

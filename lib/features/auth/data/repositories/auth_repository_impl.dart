// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación del repositorio de autenticación.
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
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on TimeoutException {
      throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } on http.ClientException catch (e) {
      throw NetworkFailure('Error de conexión: $e');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapLegacyError(e, 'Error al iniciar sesión');
    }
  }

  @override
  Future<String> register(
    String username,
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? languagePreference,
  }) async {
    try {
      _validateRegistration(username, email, password);

      final token = await remoteDatasource.register(
        username,
        email,
        password,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        languagePreference: languagePreference,
      );
      await storageService.saveToken(token);

      return token;
    } on ServerException catch (e) {
      throw _mapServerException(e);
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on TimeoutException {
      throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } on http.ClientException catch (e) {
      throw NetworkFailure('Error de conexión: $e');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapLegacyError(e, 'Error al registrar la cuenta');
    }
  }

  @override
  Future<void> logout() async {
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
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on TimeoutException {
      throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } on http.ClientException catch (e) {
      throw NetworkFailure('Error de conexión: $e');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('tiempo de espera')) {
        throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
      }
      if (msg.contains('401') || msg.contains('unauthorized')) {
        await storageService.deleteToken();
        throw const AuthenticationFailure('Sesión expirada. Por favor, inicia sesión de nuevo');
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
      throw const ValidationFailure('Introduce tu nombre de usuario o correo electrónico');
    }
    if (password.trim().isEmpty) {
      throw const ValidationFailure('Introduce tu contraseña');
    }
  }

  void _validateRegistration(String username, String email, String password) {
    if (username.trim().isEmpty) {
      throw const ValidationFailure('El nombre de usuario no puede estar vacío');
    }
    if (username.trim().length < 3) {
      throw const ValidationFailure('El nombre de usuario debe tener al menos 3 caracteres');
    }
    if (email.trim().isEmpty) {
      throw const ValidationFailure('El correo electrónico no puede estar vacío');
    }
    if (!email.contains('@') || !email.contains('.')) {
      throw const ValidationFailure('Introduce un formato de correo electrónico válido');
    }
    if (password.trim().isEmpty) {
      throw const ValidationFailure('La contraseña no puede estar vacía');
    }
    if (password.length < 8) {
      throw const ValidationFailure('La contraseña debe tener al menos 8 caracteres');
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
      case ServerErrorType.validationError:
        return ValidationFailure(e.message);
      default:
        return NetworkFailure(e.message);
    }
  }

  Failure _mapLegacyError(Object e, String prefix) {
    final raw = e.toString().replaceFirst(RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'), '').trim();
    final msg = raw.toLowerCase();

    if (msg.contains('timeout') || msg.contains('tiempo de espera')) {
      return const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } else if (msg.contains('401') || msg.contains('unauthorized') || msg.contains('invalid credentials')) {
      return AuthenticationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Usuario o contraseña incorrectos');
    } else if (msg.contains('403') || msg.contains('forbidden')) {
      return AuthenticationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Acceso denegado a la cuenta');
    } else if (msg.contains('409') || msg.contains('conflict')) {
      return ValidationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'El usuario o correo electrónico ya está registrado');
    } else if (msg.contains('400') || msg.contains('validation') || msg.contains('bad request')) {
      return ValidationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Datos no válidos');
    } else if (msg.contains('500') || msg.contains('server')) {
      return const NetworkFailure('Error del servidor. Por favor, inténtalo más tarde.');
    }
    return NetworkFailure(raw.isNotEmpty ? raw : '$prefix: ${e.toString()}');
  }
}

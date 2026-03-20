import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

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
      if (username.trim().isEmpty) {
        throw const ValidationFailure('Username cannot be empty');
      }
      if (password.trim().isEmpty) {
        throw const ValidationFailure('Password cannot be empty');
      }

      final token = await remoteDatasource.login(username, password);
      await storageService.saveToken(token);

      // CORRECCIÓN: extraemos el user_id directamente del JWT con jwt_decoder
      // en lugar de hacer una segunda llamada GET /api/auth/me, que era redundante
      // porque login_user.dart ya llama a getCurrentUser() después de login().
      try {
        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['id'];
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', (userId as num).toInt());
        }
      } catch (e) {
        // Si falla el decode del token, lo ignoramos — getCurrentUser() lo recuperará
        print('⚠️ AuthRepository: No se pudo extraer user_id del token: $e');
      }

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
      if (username.trim().isEmpty) {
        throw const ValidationFailure('Username cannot be empty');
      }
      if (email.trim().isEmpty) {
        throw const ValidationFailure('Email cannot be empty');
      }
      if (password.trim().isEmpty) {
        throw const ValidationFailure('Password cannot be empty');
      }
      // CORRECCIÓN: el backend exige mínimo 8 caracteres (UserRegistrationDTO @Size(min=8))
      if (password.length < 8) {
        throw const ValidationFailure('Password must be at least 8 characters');
      }
      if (!email.contains('@') || !email.contains('.')) {
        throw const ValidationFailure('Please enter a valid email address');
      }

      final token = await remoteDatasource.register(username, email, password);
      await storageService.saveToken(token);

      // Igual que en login, extraemos user_id del token sin hacer llamada extra
      try {
        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['id'];
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', (userId as num).toInt());
        }
      } catch (e) {
        print('⚠️ AuthRepository: No se pudo extraer user_id del token: $e');
      }

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
    try {
      await storageService.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
    } catch (e) {
      print('⚠️ AuthRepository: Error durante logout: $e');
    }
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
        await _clearSession();
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
        await _clearSession();
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      }
      await _clearSession();
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await storageService.readToken();
      if (token == null || token.isEmpty) return false;

      // Comprobamos expiración localmente antes de hacer una llamada de red
      if (JwtDecoder.isExpired(token)) {
        await _clearSession();
        return false;
      }

      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await storageService.readToken();
    } catch (e) {
      return null;
    }
  }

  Future<void> _clearSession() async {
    await storageService.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Failure _mapServerException(ServerException e) {
    switch (e.type) {
      case ServerErrorType.authentication:
      case ServerErrorType.forbidden:
        return AuthenticationFailure(e.message);
      case ServerErrorType.conflict:
        // Conflicto = usuario/email ya existe — es un error de validación, no de auth
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
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación de AuthRepository que conecta datasource y dominio
/// Maneja el almacenamiento de tokens JWT y transforma DTOs a entidades
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
      // Validar entrada
      if (username.trim().isEmpty) {
        throw const ValidationFailure('Username cannot be empty');
      }
      if (password.trim().isEmpty) {
        throw const ValidationFailure('Password cannot be empty');
      }

      // Obtener token del datasource remoto
      final token = await remoteDatasource.login(username, password);

      // Almacenar token de forma segura
      await storageService.saveToken(token);

      // Obtener información del usuario y guardar el user_id
      try {
        final userDto = await remoteDatasource.getCurrentUser();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userDto.id);
        print(
          '💾 AuthRepository: User ID ${userDto.id} guardado en SharedPreferences',
        );
      } catch (e) {
        print('⚠️ AuthRepository: Error guardando user_id: $e');
        // No lanzar error aquí, el login fue exitoso
      }

      return token;
    } on ServerException catch (e) {
      // Manejar excepciones específicas del servidor con mejor categorización
      throw _mapServerExceptionToFailure(e);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-lanzar errores de validación tal como están
    } catch (e) {
      // Manejo de errores legacy para compatibilidad con código existente
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('invalid credentials')) {
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

      // Fallo de red por defecto para errores desconocidos
      throw NetworkFailure('Login failed: ${e.toString()}');
    }
  }

  /// Mapea ServerException específicas a Failures apropiados
  Failure _mapServerExceptionToFailure(ServerException e) {
    print('🔄 AuthRepository: Mapeando ServerException a Failure');
    print('   Tipo: ${e.type}');
    print('   Mensaje: ${e.message}');
    print('   Código de estado: ${e.statusCode}');

    switch (e.type) {
      case ServerErrorType.authentication:
        return AuthenticationFailure(e.message);

      case ServerErrorType.forbidden:
        return AuthenticationFailure(e.message);

      case ServerErrorType.notFound:
        return NetworkFailure(e.message);

      case ServerErrorType.conflict:
        return AuthenticationFailure(e.message);

      case ServerErrorType.serverError:
        return NetworkFailure(e.message);

      case ServerErrorType.serviceUnavailable:
        return NetworkFailure(e.message);

      case ServerErrorType.databaseError:
        return NetworkFailure(
          'Database connection error. Please try again in a few minutes.',
        );

      case ServerErrorType.jwtError:
        return NetworkFailure(
          'Authentication system error. Please try again or contact support.',
        );

      case ServerErrorType.networkError:
        return NetworkFailure(e.message);

      case ServerErrorType.timeoutError:
        return NetworkFailure(
          'Request timeout. Please check your connection and try again.',
        );

      case ServerErrorType.validationError:
        return ValidationFailure(e.message);

      case ServerErrorType.unknownError:
      default:
        return NetworkFailure(e.message);
    }
  }

  @override
  Future<String> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      // Validar entrada
      if (username.trim().isEmpty) {
        throw const ValidationFailure('Username cannot be empty');
      }
      if (email.trim().isEmpty) {
        throw const ValidationFailure('Email cannot be empty');
      }
      if (password.trim().isEmpty) {
        throw const ValidationFailure('Password cannot be empty');
      }
      if (password.length < 6) {
        throw const ValidationFailure('Password must be at least 6 characters');
      }
      // Validación básica de email
      if (!email.contains('@') || !email.contains('.')) {
        throw const ValidationFailure('Please enter a valid email address');
      }

      // Obtener token del datasource remoto
      final token = await remoteDatasource.register(username, email, password);

      // Almacenar token de forma segura
      await storageService.saveToken(token);

      return token;
    } on ServerException catch (e) {
      // Manejar excepciones específicas del servidor
      throw _mapServerExceptionToFailure(e);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-lanzar errores de validación tal como están
    } catch (e) {
      // Manejo de errores legacy para compatibilidad
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

      // Fallo de red por defecto para errores desconocidos
      throw NetworkFailure('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Limpiar token almacenado
      await storageService.deleteToken();

      // Limpiar user_id de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      print('💾 AuthRepository: User ID eliminado de SharedPreferences');
    } catch (e) {
      // Incluso si el almacenamiento falla, debemos completar el logout
      // Registrar error pero no lanzar para evitar problemas de logout
      print('⚠️ AuthRepository: Error durante logout: $e');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Verificar si existe token
      final token = await storageService.readToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Obtener datos de usuario del datasource remoto
      final userDto = await remoteDatasource.getCurrentUser();

      // Transformar DTO a entidad antes de devolver a la capa de dominio
      return userDto.toEntity();
    } on ServerException catch (e) {
      // Manejar excepciones específicas del servidor
      if (e.type == ServerErrorType.authentication) {
        // Token inválido, limpiarlo y devolver null
        await storageService.deleteToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_id');
        throw AuthenticationFailure(e.message);
      }
      throw _mapServerExceptionToFailure(e);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } catch (e) {
      // Verificar si es un error de autenticación
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        // Token inválido, limpiarlo y devolver null
        await storageService.deleteToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_id');
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

      // Para otros errores, limpiar token y devolver null (degradación elegante)
      await storageService.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await storageService.readToken();

      // Verificación básica - token existe y no está vacío
      if (token == null || token.isEmpty) {
        return false;
      }

      // Intentar obtener usuario actual para validar token
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      // Si ocurre cualquier error, considerar usuario no logueado
      print('⚠️ AuthRepository: Error verificando login status: $e');
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await storageService.readToken();
    } catch (e) {
      // Si el almacenamiento falla, devolver null
      print('⚠️ AuthRepository: Error obteniendo token: $e');
      return null;
    }
  }
}

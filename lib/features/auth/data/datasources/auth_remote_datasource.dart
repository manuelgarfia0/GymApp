import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/user_dto.dart';

/// Tipos específicos de errores del servidor para mejor categorización
enum ServerErrorType {
  authentication, // 401 - Credenciales inválidas
  forbidden, // 403 - Acceso prohibido
  notFound, // 404 - Recurso no encontrado
  conflict, // 409 - Conflicto (usuario ya existe)
  serverError, // 500 - Error interno del servidor
  serviceUnavailable, // 503 - Servicio no disponible
  databaseError, // Error específico de base de datos
  jwtError, // Error específico de JWT
  networkError, // Error de conectividad
  timeoutError, // Error de timeout
  validationError, // Error de validación
  unknownError, // Error desconocido
}

/// Excepción específica para errores del servidor con categorización
class ServerException implements Exception {
  final String message;
  final ServerErrorType type;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ServerException({
    required this.message,
    required this.type,
    this.statusCode,
    this.details,
  });

  @override
  String toString() =>
      'ServerException: $message (Type: $type, Status: $statusCode)';
}

/// Abstract interface for authentication remote data source
abstract class AuthRemoteDatasource {
  /// Authenticates user with username and password
  /// Returns JWT token on success
  /// Throws exception on failure
  Future<String> login(String username, String password);

  /// Registers a new user account
  /// Returns JWT token on success
  /// Throws exception on failure
  Future<String> register(String username, String email, String password);

  /// Retrieves current user information from API
  /// Requires valid JWT token in headers
  /// Returns UserDto on success
  Future<UserDto> getCurrentUser();
}

/// Implementation of AuthRemoteDatasource using HTTP API
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient apiClient;

  const AuthRemoteDatasourceImpl(this.apiClient);

  @override
  Future<String> login(String username, String password) async {
    return await _executeWithRetry(() async {
      try {
        print('🔄 AuthDatasource: Enviando petición de login...');
        print('   Endpoint: ${ApiConstants.loginEndpoint}');
        print('   Username: $username');

        final response = await apiClient.post(
          Uri.parse(ApiConstants.loginEndpoint),
          body: jsonEncode({'username': username, 'password': password}),
        );

        print('📡 AuthDatasource: Respuesta recibida');
        print('   Status Code: ${response.statusCode}');
        print('   Headers: ${response.headers}');
        print('   Body: ${response.body}');

        return _handleLoginResponse(response);
      } on SocketException catch (e) {
        print('❌ AuthDatasource: Error de conexión: $e');
        throw ServerException(
          message:
              'No internet connection available. Please check your network and try again.',
          type: ServerErrorType.networkError,
          details: {'originalError': e.toString()},
        );
      } on HttpException catch (e) {
        print('❌ AuthDatasource: Error HTTP: $e');
        throw ServerException(
          message: 'Network request failed. Please try again.',
          type: ServerErrorType.networkError,
          details: {'originalError': e.toString()},
        );
      } on FormatException catch (e) {
        print('❌ AuthDatasource: Error de formato: $e');
        throw ServerException(
          message:
              'Invalid response format from server. Please contact support if this persists.',
          type: ServerErrorType.validationError,
          details: {'originalError': e.toString()},
        );
      } catch (e) {
        print('❌ AuthDatasource: Error inesperado: $e');
        if (e is ServerException) rethrow;
        throw ServerException(
          message: 'Unexpected error occurred during login: ${e.toString()}',
          type: ServerErrorType.unknownError,
          details: {'originalError': e.toString()},
        );
      }
    });
  }

  /// Maneja la respuesta del login con categorización específica de errores
  String _handleLoginResponse(dynamic response) {
    final statusCode = response.statusCode as int;
    final body = response.body as String;

    print('🔍 AuthDatasource: Analizando respuesta del servidor...');
    print('   Status Code: $statusCode');

    if (statusCode == 200) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          print('❌ AuthDatasource: Token no encontrado en la respuesta');
          throw ServerException(
            message:
                'Server response is missing authentication token. Please contact support.',
            type: ServerErrorType.serverError,
            statusCode: statusCode,
            details: {'responseBody': body},
          );
        }

        print('✅ AuthDatasource: Token recibido exitosamente');
        return token;
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(
          message: 'Failed to parse server response. Please try again.',
          type: ServerErrorType.validationError,
          statusCode: statusCode,
          details: {'responseBody': body, 'parseError': e.toString()},
        );
      }
    }

    // Manejar errores específicos del servidor
    Map<String, dynamic>? errorData;
    try {
      errorData = jsonDecode(body) as Map<String, dynamic>?;
    } catch (e) {
      print('⚠️ AuthDatasource: No se pudo parsear el cuerpo del error');
    }

    final serverMessage = errorData?['message'] as String?;
    final serverError = errorData?['error'] as String?;

    switch (statusCode) {
      case 401:
        print('❌ AuthDatasource: Credenciales inválidas (401)');
        throw ServerException(
          message:
              'Invalid username or password. Please check your credentials and try again.',
          type: ServerErrorType.authentication,
          statusCode: statusCode,
          details: errorData,
        );

      case 403:
        print('❌ AuthDatasource: Acceso prohibido (403)');
        throw ServerException(
          message:
              'Account access is restricted. Please contact support for assistance.',
          type: ServerErrorType.forbidden,
          statusCode: statusCode,
          details: errorData,
        );

      case 404:
        print('❌ AuthDatasource: Servicio no encontrado (404)');
        throw ServerException(
          message:
              'Authentication service is temporarily unavailable. Please try again later.',
          type: ServerErrorType.notFound,
          statusCode: statusCode,
          details: errorData,
        );

      case 500:
        print('❌ AuthDatasource: Error interno del servidor (500)');
        final message = _categorizeServerError(serverMessage, serverError);
        throw ServerException(
          message: message,
          type: ServerErrorType.serverError,
          statusCode: statusCode,
          details: errorData,
        );

      case 503:
        print('❌ AuthDatasource: Servicio no disponible (503)');
        throw ServerException(
          message:
              'Authentication service is temporarily down for maintenance. Please try again in a few minutes.',
          type: ServerErrorType.serviceUnavailable,
          statusCode: statusCode,
          details: errorData,
        );

      default:
        print('❌ AuthDatasource: Error del servidor desconocido ($statusCode)');
        throw ServerException(
          message:
              serverMessage ?? 'Server error occurred. Please try again later.',
          type: ServerErrorType.unknownError,
          statusCode: statusCode,
          details: errorData,
        );
    }
  }

  /// Categoriza errores 500 específicos para proporcionar mensajes más útiles
  String _categorizeServerError(String? serverMessage, String? serverError) {
    final message = (serverMessage ?? serverError ?? '').toLowerCase();

    if (message.contains('database') || message.contains('connection')) {
      return 'Database connection error. The server is experiencing connectivity issues. Please try again in a few minutes.';
    } else if (message.contains('jwt') || message.contains('token')) {
      return 'Authentication system error. There\'s an issue with the login system. Please try again or contact support.';
    } else if (message.contains('timeout')) {
      return 'Server timeout error. The request took too long to process. Please try again.';
    } else if (message.contains('configuration') ||
        message.contains('config')) {
      return 'Server configuration error. The authentication service is misconfigured. Please contact support.';
    } else {
      return 'Internal server error occurred. The authentication service is experiencing technical difficulties. Please try again later or contact support if the problem persists.';
    }
  }

  /// Ejecuta una operación con lógica de reintentos para errores temporales del servidor
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } on ServerException catch (e) {
        // Solo reintentar para errores temporales del servidor
        final shouldRetry = _shouldRetryError(e.type) && attempt < maxRetries;

        if (shouldRetry) {
          final delay = Duration(
            milliseconds:
                baseDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
          );
          print(
            '🔄 AuthDatasource: Reintentando en ${delay.inSeconds}s (intento $attempt/$maxRetries)',
          );
          await Future.delayed(delay);
          continue;
        }

        // No reintentar o se agotaron los intentos
        rethrow;
      } catch (e) {
        // Para otros tipos de errores, no reintentar
        rethrow;
      }
    }

    // Este punto no debería alcanzarse nunca
    throw ServerException(
      message: 'Maximum retry attempts exceeded',
      type: ServerErrorType.unknownError,
    );
  }

  /// Determina si un tipo de error debe ser reintentado
  bool _shouldRetryError(ServerErrorType errorType) {
    switch (errorType) {
      case ServerErrorType.serverError:
      case ServerErrorType.serviceUnavailable:
      case ServerErrorType.timeoutError:
      case ServerErrorType.networkError:
        return true;
      case ServerErrorType.authentication:
      case ServerErrorType.forbidden:
      case ServerErrorType.notFound:
      case ServerErrorType.conflict:
      case ServerErrorType.validationError:
      case ServerErrorType.jwtError:
      case ServerErrorType.databaseError:
      case ServerErrorType.unknownError:
        return false;
    }
  }

  @override
  Future<String> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await apiClient.post(
        Uri.parse(ApiConstants.registerEndpoint),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          throw Exception('Invalid response: token not found');
        }

        return token;
      } else if (response.statusCode == 409) {
        throw Exception('Username or email already exists');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<UserDto> getCurrentUser() async {
    try {
      final response = await apiClient.get(
        Uri.parse(ApiConstants.currentUserEndpoint),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserDto.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get user';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }
}

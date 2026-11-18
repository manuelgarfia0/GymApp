import 'dart:async';
import 'package:flutter/foundation.dart';
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

/// Interfaz abstracta para la fuente de datos remota de autenticación
abstract class AuthRemoteDatasource {
  Future<String> login(String username, String password);
  Future<String> register(
    String username,
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? languagePreference,
  });
  Future<UserDto> getCurrentUser();
}

/// Implementación de AuthRemoteDatasource usando la API HTTP
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  static const String _timeoutMessage =
      'Tiempo de espera agotado al conectar con el servidor. Verifica que el backend esté activo.';

  final ApiClient apiClient;

  const AuthRemoteDatasourceImpl(this.apiClient);

  @override
  Future<String> login(String username, String password) async {
    return await _executeWithRetry(() async {
      try {
        debugPrint('🔄 AuthDatasource: Enviando petición de login...');
        debugPrint('   Endpoint: ${ApiConstants.loginEndpoint}');
        debugPrint('   Username: $username');

        final response = await apiClient.post(
          Uri.parse(ApiConstants.loginEndpoint),
          body: jsonEncode({'username': username, 'password': password}),
        );

        debugPrint('📡 AuthDatasource: Respuesta recibida (${response.statusCode})');

        return _handleLoginResponse(response);
      } on SocketException catch (e) {
        debugPrint('❌ AuthDatasource: Error de conexión: $e');
        throw ServerException(
          message: 'No hay conexión a internet disponible. Comprueba tu red.',
          type: ServerErrorType.networkError,
          details: {'originalError': e.toString()},
        );
      } on TimeoutException catch (e) {
        debugPrint('⏰ AuthDatasource: Tiempo de espera agotado en login: $e');
        throw ServerException(
          message: _timeoutMessage,
          type: ServerErrorType.timeoutError,
          details: {'originalError': e.toString()},
        );
      } on HttpException catch (e) {
        debugPrint('❌ AuthDatasource: Error HTTP: $e');
        throw ServerException(
          message: 'Error en la petición de red. Inténtalo de nuevo.',
          type: ServerErrorType.networkError,
          details: {'originalError': e.toString()},
        );
      } on FormatException catch (e) {
        debugPrint('❌ AuthDatasource: Error de formato: $e');
        throw ServerException(
          message: 'Formato de respuesta del servidor no válido.',
          type: ServerErrorType.validationError,
          details: {'originalError': e.toString()},
        );
      } catch (e) {
        debugPrint('❌ AuthDatasource: Error inesperado: $e');
        if (e is ServerException) rethrow;
        throw ServerException(
          message: 'Error inesperado durante el login: ${e.toString()}',
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

    if (statusCode == 200) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          throw ServerException(
            message: 'La respuesta del servidor no contiene el token de sesión.',
            type: ServerErrorType.serverError,
            statusCode: statusCode,
            details: {'responseBody': body},
          );
        }

        return token;
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(
          message: 'Error al interpretar la respuesta del servidor.',
          type: ServerErrorType.validationError,
          statusCode: statusCode,
          details: {'responseBody': body, 'parseError': e.toString()},
        );
      }
    }

    Map<String, dynamic>? errorData;
    try {
      errorData = jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {}

    String? serverMessage;
    if (errorData != null) {
      if (errorData['fieldErrors'] is Map) {
        final fields = errorData['fieldErrors'] as Map;
        if (fields.isNotEmpty) {
          serverMessage = fields.values.join(', ');
        }
      }
      serverMessage ??= errorData['message'] as String?;
    }
    final serverError = errorData?['error'] as String?;

    switch (statusCode) {
      case 400:
        throw ServerException(
          message: serverMessage ?? 'Datos de inicio de sesión no válidos.',
          type: ServerErrorType.validationError,
          statusCode: statusCode,
          details: errorData,
        );

      case 401:
        throw ServerException(
          message: serverMessage ?? 'Usuario o contraseña incorrectos. Verifica tus credenciales.',
          type: ServerErrorType.authentication,
          statusCode: statusCode,
          details: errorData,
        );

      case 403:
        throw ServerException(
          message: serverMessage ?? 'Acceso a la cuenta denegado.',
          type: ServerErrorType.forbidden,
          statusCode: statusCode,
          details: errorData,
        );

      case 404:
        throw ServerException(
          message: serverMessage ?? 'Servicio de autenticación no encontrado en el servidor.',
          type: ServerErrorType.notFound,
          statusCode: statusCode,
          details: errorData,
        );

      case 409:
        throw ServerException(
          message: serverMessage ?? 'Conflicto con los datos proporcionados.',
          type: ServerErrorType.conflict,
          statusCode: statusCode,
          details: errorData,
        );

      case 500:
        final message = serverMessage ?? _categorizeServerError(serverMessage, serverError);
        throw ServerException(
          message: message,
          type: ServerErrorType.serverError,
          statusCode: statusCode,
          details: errorData,
        );

      case 503:
        throw ServerException(
          message: serverMessage ?? 'El servicio está en mantenimiento temporalmente. Inténtalo en unos minutos.',
          type: ServerErrorType.serviceUnavailable,
          statusCode: statusCode,
          details: errorData,
        );

      default:
        throw ServerException(
          message: serverMessage ?? 'Error del servidor ($statusCode). Inténtalo más tarde.',
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
      return 'Error de conexión con la base de datos en el servidor. Inténtalo en unos minutos.';
    } else if (message.contains('jwt') || message.contains('token')) {
      return 'Error en el sistema de autenticación de tokens. Vuelve a iniciar sesión.';
    } else if (message.contains('timeout')) {
      return 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
    } else {
      return 'Ha ocurrido un error interno en el servidor. Inténtalo más tarde.';
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
        final shouldRetry = _shouldRetryError(e.type) && attempt < maxRetries;

        if (shouldRetry) {
          final delay = Duration(
            milliseconds: baseDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
          );
          debugPrint('🔄 AuthDatasource: Reintentando en ${delay.inSeconds}s (intento $attempt/$maxRetries)');
          await Future.delayed(delay);
          continue;
        }

        rethrow;
      } catch (e) {
        rethrow;
      }
    }

    throw const ServerException(
      message: 'Se superó el número máximo de reintentos de conexión.',
      type: ServerErrorType.unknownError,
    );
  }

  bool _shouldRetryError(ServerErrorType errorType) {
    switch (errorType) {
      case ServerErrorType.serviceUnavailable:
        return true;
      case ServerErrorType.serverError:
      case ServerErrorType.timeoutError:
      case ServerErrorType.networkError:
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
    String password, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? languagePreference,
  }) async {
    try {
      final response = await apiClient.post(
        Uri.parse(ApiConstants.registerEndpoint),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
          if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
          if (dateOfBirth != null && dateOfBirth.isNotEmpty)
            'dateOfBirth': dateOfBirth,
          if (languagePreference != null && languagePreference.isNotEmpty)
            'languagePreference': languagePreference,
        }),
      );

      final statusCode = response.statusCode;
      final body = response.body;

      if (statusCode == 201 || statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          throw const ServerException(
            message: 'El servidor no devolvió el token de registro.',
            type: ServerErrorType.serverError,
            statusCode: 200,
          );
        }

        return token;
      }

      // Parsear cuerpo de error detallado del backend
      Map<String, dynamic>? errorData;
      try {
        errorData = jsonDecode(body) as Map<String, dynamic>?;
      } catch (_) {}

      String? specificMessage;
      if (errorData != null) {
        if (errorData['fieldErrors'] is Map) {
          final fields = errorData['fieldErrors'] as Map;
          if (fields.isNotEmpty) {
            specificMessage = fields.values.join(', ');
          }
        }
        specificMessage ??= errorData['message'] as String?;
      }

      if (statusCode == 409) {
        throw ServerException(
          message: specificMessage ?? 'El usuario o correo electrónico ya están registrados.',
          type: ServerErrorType.conflict,
          statusCode: statusCode,
          details: errorData,
        );
      } else if (statusCode == 400) {
        throw ServerException(
          message: specificMessage ?? 'Datos de registro no válidos.',
          type: ServerErrorType.validationError,
          statusCode: statusCode,
          details: errorData,
        );
      } else {
        throw ServerException(
          message: specificMessage ?? 'Error en el registro ($statusCode). Inténtalo más tarde.',
          type: ServerErrorType.serverError,
          statusCode: statusCode,
          details: errorData,
        );
      }
    } on SocketException {
      throw const ServerException(
        message: 'No hay conexión a internet disponible. Comprueba tu red.',
        type: ServerErrorType.networkError,
      );
    } on TimeoutException {
      throw const ServerException(
        message: _timeoutMessage,
        type: ServerErrorType.timeoutError,
      );
    } on FormatException {
      throw const ServerException(
        message: 'Formato de respuesta del servidor no válido.',
        type: ServerErrorType.validationError,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Error inesperado durante el registro: $e',
        type: ServerErrorType.unknownError,
      );
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
        throw const ServerException(
          message: 'Sesión expirada o no autenticada.',
          type: ServerErrorType.authentication,
          statusCode: 401,
        );
      } else {
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (_) {}

        final errorMessage = errorData?['message'] as String? ?? 'Error al obtener la información del usuario';
        throw ServerException(
          message: errorMessage,
          type: ServerErrorType.serverError,
          statusCode: response.statusCode,
          details: errorData,
        );
      }
    } on SocketException {
      throw const ServerException(
        message: 'No hay conexión a internet disponible.',
        type: ServerErrorType.networkError,
      );
    } on TimeoutException {
      throw const ServerException(
        message: _timeoutMessage,
        type: ServerErrorType.timeoutError,
      );
    } on FormatException {
      throw const ServerException(
        message: 'Formato de respuesta del servidor no válido.',
        type: ServerErrorType.validationError,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Error inesperado al obtener usuario: $e',
        type: ServerErrorType.unknownError,
      );
    }
  }
}

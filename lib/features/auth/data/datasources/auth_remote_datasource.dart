import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/user_dto.dart';

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          print('❌ AuthDatasource: Token no encontrado en la respuesta');
          throw Exception('Invalid response: token not found');
        }

        print('✅ AuthDatasource: Token recibido exitosamente');
        return token;
      } else if (response.statusCode == 401) {
        print('❌ AuthDatasource: Credenciales inválidas (401)');
        throw Exception('Invalid credentials');
      } else {
        print('❌ AuthDatasource: Error del servidor (${response.statusCode})');
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] as String? ?? 'Login failed';
        print('   Error message: $errorMessage');
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      print('❌ AuthDatasource: Error de conexión: $e');
      throw Exception('No internet connection');
    } on FormatException catch (e) {
      print('❌ AuthDatasource: Error de formato: $e');
      throw Exception('Invalid response format');
    } catch (e) {
      print('❌ AuthDatasource: Error inesperado: $e');
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
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

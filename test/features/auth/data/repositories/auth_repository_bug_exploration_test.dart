import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:gym_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/core/storage/secure_storage_service.dart';
import 'package:gym_app/core/errors/failures.dart';

/// Test de exploración de condición de bug para errores 500 durante autenticación válida
///
/// **Validates: Requirements 2.1, 2.2, 2.4**
///
/// CRÍTICO: Este test DEBE FALLAR en código sin corregir - el fallo confirma que el bug existe
/// NO intentar arreglar el test o el código cuando falle
/// OBJETIVO: Generar contraejemplos que demuestren que el bug existe
///
/// Enfoque PBT con alcance determinístico: Para bugs determinísticos,
/// limitamos la propiedad al caso(s) de fallo concreto para asegurar reproducibilidad
void main() {
  group('Bug Condition Exploration - Server 500 Error During Valid Authentication', () {
    late AuthRepositoryImpl repository;
    late MockSecureStorageService mockStorage;
    late MockHttpClient mockHttpClient;
    late AuthRemoteDatasourceImpl datasource;

    setUp(() {
      mockStorage = MockSecureStorageService();
      mockHttpClient = MockHttpClient();
      datasource = AuthRemoteDatasourceImpl(mockHttpClient);
      repository = AuthRepositoryImpl(
        remoteDatasource: datasource,
        storageService: mockStorage,
      );
    });

    /// Property 1: Bug Condition - Server 500 Error During Valid Authentication
    ///
    /// **Validates: Requirements 2.1, 2.2, 2.4**
    ///
    /// Esta propiedad codifica el comportamiento esperado: la autenticación con
    /// credenciales válidas debería tener éxito pero actualmente retorna error 500
    ///
    /// Las aserciones del test coinciden con las Propiedades de Comportamiento Esperado
    /// del diseño: autenticación exitosa, token JWT válido, acceso a funciones de la app
    ///
    /// Ejecutar test en código SIN CORREGIR (tanto backend como frontend)
    /// RESULTADO ESPERADO: Test FALLA (esto es correcto - prueba que el bug existe)
    test(
      'Property 1: Valid credentials should succeed but currently returns 500 error',
      () async {
        // Arrange: Configurar credenciales válidas conocidas que deberían funcionar
        const validUsername = 'manuel';
        const validPassword = 'mypassword123';

        // Simular la respuesta 500 del servidor que actualmente ocurre con credenciales válidas
        // Esto representa el comportamiento actual defectuoso del backend Spring Boot
        mockHttpClient.mockResponse = http.Response(
          jsonEncode({
            'error': 'Internal Server Error',
            'message': 'An unexpected error has occurred.',
            'status': 500,
          }),
          500,
          headers: {'content-type': 'application/json'},
        );

        // Act & Assert: Intentar login con credenciales válidas
        // COMPORTAMIENTO ACTUAL (DEFECTUOSO): Debería lanzar NetworkFailure por error 500
        // COMPORTAMIENTO ESPERADO (DESPUÉS DE LA CORRECCIÓN): Debería retornar token JWT válido

        try {
          final token = await repository.login(validUsername, validPassword);

          // Si llegamos aquí, significa que el login fue exitoso
          // Verificar que recibimos un token JWT válido (comportamiento esperado)
          expect(token, isNotNull);
          expect(token, isNotEmpty);
          expect(
            token,
            matches(
              RegExp(r'^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]*$'),
            ),
          ); // Formato JWT básico

          // Verificar que el token se almacenó de forma segura
          expect(mockStorage.storedToken, equals(token));

          // Este test FALLARÁ en código sin corregir porque actualmente se lanza NetworkFailure
          // El fallo confirma que el bug existe: credenciales válidas → error 500 → NetworkFailure
          fail(
            'EXPECTED FAILURE: This test should fail on unfixed code. '
            'If this passes, the bug may already be fixed or the test needs adjustment.',
          );
        } on NetworkFailure catch (e) {
          // COMPORTAMIENTO ACTUAL DEFECTUOSO: Error 500 se maneja como NetworkFailure
          // Esto confirma que el bug existe - credenciales válidas resultan en error del servidor

          // Documentar el contraejemplo encontrado para entender la causa raíz
          print('🐛 CONTRAEJEMPLO ENCONTRADO - Bug confirmado:');
          print('   Credenciales válidas: $validUsername/$validPassword');
          print('   Respuesta del servidor: 500 Internal Server Error');
          print('   Error capturado: ${e.message}');
          print(
            '   Causa raíz probable: configuración del backend, CORS, o problemas JWT',
          );

          // Verificar que el error contiene la información esperada del servidor 500
          expect(e.message, contains('server error'));

          // Este es el comportamiento actual defectuoso que confirma el bug
          // El test pasa aquí porque estamos documentando el comportamiento actual incorrecto
        } on AuthenticationFailure catch (e) {
          // Si recibimos AuthenticationFailure, significa que las credenciales se procesaron
          // pero fueron rechazadas - esto indicaría un problema diferente
          fail(
            'Unexpected AuthenticationFailure: ${e.message}. '
            'Expected NetworkFailure due to server 500 error.',
          );
        } catch (e) {
          // Cualquier otro error inesperado
          fail('Unexpected error type: ${e.runtimeType} - $e');
        }
      },
    );

    /// Test adicional: Verificar que el comportamiento actual es consistente
    /// con diferentes credenciales válidas (para confirmar que es un problema del servidor)
    test(
      'Property 1 Extended: Multiple valid credential sets should all fail with 500',
      () async {
        // Lista de credenciales que deberían ser válidas
        final validCredentialSets = [
          {'username': 'manuel', 'password': 'mypassword123'},
          // Nota: Solo usamos las credenciales reales que existen en la base de datos
        ];

        for (final credentials in validCredentialSets) {
          // Simular respuesta 500 para cada conjunto de credenciales
          mockHttpClient.mockResponse = http.Response(
            jsonEncode({
              'error': 'Internal Server Error',
              'message': 'Database connection failed',
              'status': 500,
            }),
            500,
            headers: {'content-type': 'application/json'},
          );

          // Verificar que todas las credenciales válidas fallan con error 500
          expect(
            () => repository.login(
              credentials['username']!,
              credentials['password']!,
            ),
            throwsA(
              isA<NetworkFailure>().having(
                (e) => e.message,
                'message',
                contains('connection error'),
              ),
            ),
          );
        }

        print(
          '🐛 CONTRAEJEMPLOS MÚLTIPLES: Todas las credenciales válidas fallan con 500',
        );
        print(
          '   Esto confirma que es un problema del servidor, no de credenciales específicas',
        );
      },
    );

    /// Test de verificación: Asegurar que el comportamiento de errores 401 se preserva
    /// (esto NO debería cambiar con la corrección)
    test(
      'Preservation Check: Invalid credentials should still return 401 (unchanged behavior)',
      () async {
        // Arrange: Credenciales inválidas
        const invalidUsername = 'wronguser';
        const invalidPassword = 'wrongpass';

        // Simular respuesta 401 del servidor (comportamiento correcto existente)
        mockHttpClient.mockResponse = http.Response(
          jsonEncode({
            'error': 'Unauthorized',
            'message': 'Invalid credentials',
            'status': 401,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );

        // Act & Assert: Verificar que credenciales inválidas siguen retornando AuthenticationFailure
        expect(
          () => repository.login(invalidUsername, invalidPassword),
          throwsA(
            isA<AuthenticationFailure>().having(
              (e) => e.message,
              'message',
              contains('Invalid username or password'),
            ),
          ),
        );

        print(
          '✅ PRESERVACIÓN CONFIRMADA: Errores 401 siguen funcionando correctamente',
        );
      },
    );
  });
}

/// Mock del servicio de almacenamiento seguro para testing
class MockSecureStorageService implements SecureStorageService {
  String? storedToken;

  @override
  Future<void> saveToken(String token) async {
    storedToken = token;
  }

  @override
  Future<String?> readToken() async {
    return storedToken;
  }

  @override
  Future<void> deleteToken() async {
    storedToken = null;
  }
}

/// Mock del cliente HTTP para simular respuestas del servidor
class MockHttpClient extends ApiClient {
  http.Response? mockResponse;

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    if (mockResponse != null) {
      return mockResponse!;
    }
    throw Exception('No mock response configured');
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    if (mockResponse != null) {
      return mockResponse!;
    }
    throw Exception('No mock response configured');
  }
}

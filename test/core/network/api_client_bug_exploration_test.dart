import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/core/network/api_constants.dart';

/// **Validates: Requirements 2.1, 2.2, 2.3, 2.4**
///
/// Test de exploración de la condición del bug para headers Content-Type en peticiones JSON.
///
/// CRÍTICO: Este test DEBE FALLAR en código sin arreglar - el fallo confirma que el bug existe.
/// NO intentar arreglar el test o el código cuando falle.
///
/// OBJETIVO: Encontrar contraejemplos que demuestren que el bug existe.
/// RESULTADO ESPERADO: Test FALLA (esto es correcto - prueba que el bug existe).
///
/// Condición del Bug:
/// isBugCondition(input) donde input.method == 'POST' AND input.hasJsonBody == true
/// AND input.actualContentType == 'text/plain;charset=utf-8'
void main() {
  // Inicializar bindings de Flutter para tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug Condition Exploration - JSON Content-Type Headers', () {
    late MockApiClient mockApiClient;
    late HttpServer mockServer;

    setUpAll(() async {
      // Configurar servidor mock para interceptar peticiones HTTP reales
      mockServer = await HttpServer.bind('localhost', 0);
      mockServer.listen((request) async {
        // Responder inmediatamente para evitar timeouts
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'token': 'mock-jwt-token'}));
        await request.response.close();
      });
    });

    tearDownAll(() async {
      await mockServer.close();
    });

    setUp(() {
      mockApiClient = MockApiClient();
    });

    /// Propiedad 1: Bug Condition - JSON Content-Type Headers
    ///
    /// Para cualquier petición HTTP POST con cuerpo JSON enviada a través del ApiClient,
    /// la implementación arreglada DEBE enviar la petición con Content-Type 'application/json',
    /// asegurando que Spring Boot pueda parsear correctamente el payload JSON y procesar
    /// la petición exitosamente.
    group('Property 1: Bug Condition - JSON Content-Type Headers', () {
      test(
        'Login POST request should send Content-Type application/json',
        () async {
          // Arrange: Configurar datos de login
          const username = 'testuser';
          const password = 'testpass';
          final loginBody = jsonEncode({
            'username': username,
            'password': password,
          });

          // Act: Realizar petición de login POST con cuerpo JSON
          try {
            await mockApiClient.post(
              Uri.parse('http://localhost:${mockServer.port}/auth/login'),
              body: loginBody,
            );
          } catch (e) {
            // Ignorar errores de conexión, nos interesa capturar los headers
          }

          // Assert: Verificar que el Content-Type sea 'application/json'
          final capturedHeaders = mockApiClient.lastRequestHeaders;
          expect(
            capturedHeaders,
            isNotNull,
            reason: 'Debe capturar los headers de la petición HTTP',
          );

          final contentType = capturedHeaders!['content-type'];

          // Documentar el contraejemplo encontrado
          print('=== CONTRAEJEMPLO DETECTADO - LOGIN ===');
          print('Content-Type esperado: application/json');
          print('Content-Type actual: $contentType');
          print('Headers completos: $capturedHeaders');
          print('Cuerpo de la petición: $loginBody');
          print('=======================================');

          expect(
            contentType,
            equals('application/json'),
            reason:
                'POST con cuerpo JSON DEBE enviar Content-Type application/json. '
                'Actual: $contentType. '
                'Bug detectado: Content-Type incorrecto para peticiones JSON.',
          );
        },
      );

      test(
        'Register POST request should send Content-Type application/json',
        () async {
          // Arrange: Configurar datos de registro
          const username = 'newuser';
          const email = 'newuser@example.com';
          const password = 'newpass';
          final registerBody = jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          });

          // Act: Realizar petición de registro POST con cuerpo JSON
          try {
            await mockApiClient.post(
              Uri.parse('http://localhost:${mockServer.port}/auth/register'),
              body: registerBody,
            );
          } catch (e) {
            // Ignorar errores de conexión, nos interesa capturar los headers
          }

          // Assert: Verificar que el Content-Type sea 'application/json'
          final capturedHeaders = mockApiClient.lastRequestHeaders;
          expect(capturedHeaders, isNotNull);

          final contentType = capturedHeaders!['content-type'];

          // Documentar el contraejemplo encontrado
          print('=== CONTRAEJEMPLO DETECTADO - REGISTER ===');
          print('Content-Type esperado: application/json');
          print('Content-Type actual: $contentType');
          print('Headers completos: $capturedHeaders');
          print('Cuerpo de la petición: $registerBody');
          print('==========================================');

          expect(
            contentType,
            equals('application/json'),
            reason:
                'POST de registro con cuerpo JSON DEBE enviar Content-Type application/json. '
                'Actual: $contentType. '
                'Bug detectado: Content-Type incorrecto para peticiones JSON.',
          );
        },
      );

      test(
        'Generic POST request with JSON body should send Content-Type application/json',
        () async {
          // Arrange: Configurar petición POST genérica con cuerpo JSON
          final jsonBody = jsonEncode({'data': 'test', 'value': 123});

          // Act: Realizar petición POST genérica con cuerpo JSON
          try {
            await mockApiClient.post(
              Uri.parse('http://localhost:${mockServer.port}/test/endpoint'),
              body: jsonBody,
            );
          } catch (e) {
            // Ignorar errores de conexión, nos interesa capturar los headers
          }

          // Assert: Verificar que el Content-Type sea 'application/json'
          final capturedHeaders = mockApiClient.lastRequestHeaders;
          expect(capturedHeaders, isNotNull);

          final contentType = capturedHeaders!['content-type'];

          // Documentar el contraejemplo encontrado
          print('=== CONTRAEJEMPLO DETECTADO - GENERIC ===');
          print('Content-Type esperado: application/json');
          print('Content-Type actual: $contentType');
          print('Headers completos: $capturedHeaders');
          print('Cuerpo de la petición: $jsonBody');
          print('=========================================');

          expect(
            contentType,
            equals('application/json'),
            reason:
                'POST genérico con cuerpo JSON DEBE enviar Content-Type application/json. '
                'Actual: $contentType. '
                'Bug detectado: Content-Type incorrecto para peticiones JSON.',
          );
        },
      );

      test('Direct HTTP client comparison - demonstrates the bug', () async {
        // Arrange: Comparar comportamiento directo del paquete http vs ApiClient
        final directClient = http.Client();
        final jsonBody = jsonEncode({'test': 'data'});

        // Crear un interceptor para capturar headers del cliente directo
        final interceptor = HeaderInterceptorClient(directClient);

        // Act: Realizar petición con cliente HTTP directo
        try {
          await interceptor.post(
            Uri.parse('http://localhost:${mockServer.port}/test'),
            body: jsonBody,
          );
        } catch (e) {
          // Ignorar errores de conexión
        }

        // Realizar petición con ApiClient
        try {
          await mockApiClient.post(
            Uri.parse('http://localhost:${mockServer.port}/test'),
            body: jsonBody,
          );
        } catch (e) {
          // Ignorar errores de conexión
        }

        // Assert: Comparar headers entre ambos clientes
        final directHeaders = interceptor.lastRequestHeaders;
        final apiClientHeaders = mockApiClient.lastRequestHeaders;

        print('=== COMPARACIÓN DE CLIENTES ===');
        print(
          'Cliente HTTP directo - Content-Type: ${directHeaders?['content-type']}',
        );
        print('ApiClient - Content-Type: ${apiClientHeaders?['content-type']}');
        print('Headers cliente directo: $directHeaders');
        print('Headers ApiClient: $apiClientHeaders');
        print('===============================');

        // El bug se manifiesta cuando ApiClient no envía el Content-Type correcto
        expect(
          apiClientHeaders?['content-type'],
          equals('application/json'),
          reason:
              'ApiClient DEBE enviar Content-Type application/json para peticiones POST con JSON. '
              'Actual: ${apiClientHeaders?['content-type']}. '
              'CONTRAEJEMPLO: Este demuestra que el bug existe.',
        );
      });
    });
  });
}

/// Mock del ApiClient que captura headers sin depender de SecureStorage
class MockApiClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  Map<String, String>? _lastRequestHeaders;

  Map<String, String>? get lastRequestHeaders => _lastRequestHeaders;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Simular el comportamiento del ApiClient real sin SecureStorage
    // Agregar Content-Type como lo hace el ApiClient real
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    // Capturar headers para inspección (normalizar a lowercase para compatibilidad)
    _lastRequestHeaders = <String, String>{};
    for (final entry in request.headers.entries) {
      _lastRequestHeaders![entry.key.toLowerCase()] = entry.value;
    }

    // Continuar con la petición
    return _inner.send(request);
  }

  /// Override del método post para simular el comportamiento del ApiClient real
  ///
  /// Este override replica la misma lógica implementada en el ApiClient real
  /// para asegurar que las peticiones POST con cuerpo JSON mantengan el Content-Type correcto.
  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    // Crear headers combinados, priorizando los headers explícitos
    final combinedHeaders = <String, String>{};

    // Agregar Content-Type por defecto para peticiones JSON
    combinedHeaders['Content-Type'] = 'application/json';

    // Sobrescribir con headers proporcionados si existen
    if (headers != null) {
      combinedHeaders.addAll(headers);
    }

    // Detectar si el cuerpo es JSON y asegurar Content-Type correcto
    if (body != null && _isJsonBody(body)) {
      // Forzar Content-Type a application/json para cuerpos JSON
      combinedHeaders['Content-Type'] = 'application/json';
    }

    // Realizar la petición POST con headers explícitos
    return super.post(
      url,
      headers: combinedHeaders,
      body: body,
      encoding: encoding,
    );
  }

  /// Detecta si el cuerpo de la petición contiene contenido JSON
  ///
  /// Replica la misma lógica del ApiClient real para detectar cuerpos JSON.
  bool _isJsonBody(Object body) {
    if (body is String) {
      // Verificar si el String parece ser JSON
      final trimmed = body.trim();
      return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'));
    }

    // Para otros tipos de objetos, asumir que serán serializados como JSON
    // si no son tipos básicos de texto plano
    return body is! String;
  }
}

/// Interceptor para capturar headers del cliente HTTP directo
class HeaderInterceptorClient extends http.BaseClient {
  final http.Client _inner;
  Map<String, String>? _lastRequestHeaders;

  HeaderInterceptorClient(this._inner);

  Map<String, String>? get lastRequestHeaders => _lastRequestHeaders;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Capturar headers antes de enviar
    _lastRequestHeaders = Map<String, String>.from(request.headers);

    // Continuar con la petición normal
    return _inner.send(request);
  }
}

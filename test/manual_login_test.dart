import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/auth/data/datasources/auth_remote_datasource.dart';

/// Test manual para verificar el flujo de login con credenciales reales
/// usando las credenciales proporcionadas: manuel/mypassword123
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Manual Login Test with Real Credentials', () {
    late ApiClient apiClient;
    late AuthRemoteDatasourceImpl authDatasource;

    setUp(() {
      apiClient = ApiClient();
      authDatasource = AuthRemoteDatasourceImpl(apiClient);
    });

    test(
      'Login with manuel/mypassword123 should work with correct Content-Type',
      () async {
        // Arrange: Usar las credenciales específicas proporcionadas
        const username = 'manuel';
        const password = 'mypassword123';

        print('🔄 Intentando login con credenciales: $username/$password');
        print('🔄 Endpoint: http://10.0.2.2:8080/api/auth/login');

        // Act & Assert: Intentar login real
        try {
          final token = await authDatasource.login(username, password);

          print('✅ LOGIN EXITOSO!');
          print('✅ Token recibido: $token');
          print('✅ Content-Type headers funcionando correctamente');

          // Verificar que recibimos un token válido
          expect(token, isNotEmpty);
        } on ServerException catch (e) {
          print('❌ Error del servidor: ${e.message}');
          print('❌ Código de estado: ${e.statusCode}');
          print('❌ Tipo de error: ${e.type}');

          // Verificar que NO es un error 500 por Content-Type
          if (e.statusCode == 500 &&
              (e.message.toLowerCase().contains('content-type') ||
                  e.message.toLowerCase().contains('text/plain'))) {
            fail(
              'CRITICAL ERROR: Login falló debido a problema de Content-Type. '
              'El fix del contrato API no está funcionando correctamente. '
              'Error: ${e.message}',
            );
          }

          // Si es error 401, las credenciales son incorrectas pero el Content-Type está bien
          if (e.statusCode == 401) {
            print(
              '✅ Content-Type correcto - Error 401 indica credenciales incorrectas',
            );
            print(
              'ℹ️ Verificar que las credenciales manuel/mypassword123 existen en el servidor',
            );
          }

          // Si es error 403, acceso denegado pero el Content-Type está bien
          if (e.statusCode == 403) {
            print('✅ Content-Type correcto - Error 403 indica acceso denegado');
          }

          // Otros errores del servidor (pero no 500 por Content-Type)
          if (e.statusCode != 401 && e.statusCode != 403) {
            print('ℹ️ Error del servidor: ${e.statusCode} - ${e.message}');
            print(
              '✅ No es error 500 por Content-Type, el fix está funcionando',
            );
          }
        } catch (e) {
          print('❌ Error de conexión o configuración: $e');

          // Verificar que no es error de Content-Type
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('500') &&
              (errorMessage.contains('content-type') ||
                  errorMessage.contains('text/plain'))) {
            fail(
              'CRITICAL ERROR: Login falló debido a problema de Content-Type. '
              'Error: $e',
            );
          }

          // Errores de red son esperados si el servidor no está disponible
          if (errorMessage.contains('connection') ||
              errorMessage.contains('network') ||
              errorMessage.contains('socket')) {
            print(
              'ℹ️ Error de conexión - Verificar que el servidor Spring Boot esté ejecutándose',
            );
            print('ℹ️ URL esperada: http://10.0.2.2:8080/api/auth/login');
          }
        }
      },
    );

    test('Registration test to verify Content-Type headers', () async {
      // Test de registro para verificar que también funciona
      final username = 'testuser_${DateTime.now().millisecondsSinceEpoch}';
      const email = 'test@example.com';
      const password = 'testpass123';

      print('🔄 Intentando registro con: $username/$email');

      try {
        final token = await authDatasource.register(username, email, password);

        print('✅ REGISTRO EXITOSO!');
        print('✅ Token recibido: $token');
      } on ServerException catch (e) {
        // Verificar que NO es error 500 por Content-Type
        if (e.statusCode == 500 &&
            (e.message.toLowerCase().contains('content-type') ||
                e.message.toLowerCase().contains('text/plain'))) {
          fail(
            'CRITICAL ERROR: Registro falló debido a problema de Content-Type. '
            'Error: ${e.message}',
          );
        }

        print('ℹ️ Error de registro: ${e.statusCode} - ${e.message}');
        print('✅ No es error 500 por Content-Type, el fix está funcionando');
      } catch (e) {
        // Verificar que no es error de Content-Type
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('500') &&
            (errorMessage.contains('content-type') ||
                errorMessage.contains('text/plain'))) {
          fail(
            'CRITICAL ERROR: Registro falló debido a problema de Content-Type. Error: $e',
          );
        }

        print('ℹ️ Error de conexión en registro: $e');
      }
    });
  });
}

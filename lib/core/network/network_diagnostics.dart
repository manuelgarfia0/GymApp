import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

/// Utilidad para diagnosticar problemas de conectividad con la API
class NetworkDiagnostics {
  static Future<void> testConnectivity() async {
    print('🔍 Iniciando diagnóstico de red...');

    // Test 1: Conectividad básica
    await _testBasicConnectivity();

    // Test 2: Endpoints específicos
    await _testApiEndpoints();
  }

  static Future<void> _testBasicConnectivity() async {
    print('\n📡 Test 1: Conectividad básica');

    try {
      final client = http.Client();

      // Probar conexión a la URL base
      print('Probando conexión a: ${ApiConstants.baseUrl}');

      final response = await client
          .get(Uri.parse(ApiConstants.baseUrl))
          .timeout(const Duration(seconds: 5));

      print('✅ Respuesta recibida - Status: ${response.statusCode}');
      print('Headers: ${response.headers}');
    } on SocketException catch (e) {
      print('❌ Error de conexión: $e');
      print('💡 Posibles causas:');
      print('   - El servidor no está corriendo');
      print('   - Firewall bloqueando la conexión');
      print('   - IP/Puerto incorrecto');
    } on TimeoutException catch (e) {
      print('⏰ Timeout: $e');
      print('💡 El servidor está tardando mucho en responder');
    } catch (e) {
      print('❌ Error inesperado: $e');
    }
  }

  static Future<void> _testApiEndpoints() async {
    print('\n🎯 Test 2: Endpoints específicos');

    final endpoints = [
      '${ApiConstants.baseUrl}/test', // Endpoint de prueba
      '${ApiConstants.baseUrl}/health-check', // Health check
      ApiConstants.loginEndpoint,
      ApiConstants.registerEndpoint,
      ApiConstants.currentUserEndpoint,
      ApiConstants.exercisesEndpoint,
    ];

    for (final endpoint in endpoints) {
      await _testEndpoint(endpoint);
    }
  }

  static Future<void> _testEndpoint(String endpoint) async {
    try {
      print('\nProbando: $endpoint');

      final client = http.Client();
      final response = await client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 3));

      print('Status: ${response.statusCode}');

      if (response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          final jsonStr = json.toString();
          final maxLength = jsonStr.length > 100 ? 100 : jsonStr.length;
          print('Respuesta JSON válida: ${jsonStr.substring(0, maxLength)}...');

          // Si es un error 500, mostrar más detalles
          if (response.statusCode == 500) {
            print('🔍 Error 500 details:');
            if (json is Map && json.containsKey('message')) {
              print('   Message: ${json['message']}');
            }
            if (json is Map && json.containsKey('error')) {
              print('   Error: ${json['error']}');
            }
            if (json is Map && json.containsKey('trace')) {
              final trace = json['trace'].toString();
              final traceLength = trace.length > 200 ? 200 : trace.length;
              print('   Trace: ${trace.substring(0, traceLength)}...');
            }
          }
        } catch (e) {
          final maxLength = response.body.length > 100
              ? 100
              : response.body.length;
          print(
            'Respuesta no-JSON: ${response.body.substring(0, maxLength)}...',
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Test específico para el endpoint de login
  static Future<void> testLogin(String username, String password) async {
    print('\n🔐 Test de Login');
    print('Endpoint: ${ApiConstants.loginEndpoint}');
    print('Datos: {"username": "$username", "password": "***"}');

    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('Estructura de respuesta: ${data.keys.toList()}');

          if (data.containsKey('token')) {
            final token = data['token'] as String;
            print('✅ Token recibido: ${token.substring(0, 20)}...');
          } else {
            print('❌ Token no encontrado en la respuesta');
            print('Campos disponibles: ${data.keys.toList()}');
          }
        } catch (e) {
          print('❌ Error parseando JSON: $e');
        }
      } else if (response.statusCode == 401) {
        print('❌ Credenciales inválidas (401)');
      } else if (response.statusCode == 403) {
        print('❌ Acceso prohibido (403) - Verificar CORS');
      } else if (response.statusCode == 500) {
        print('❌ Error del servidor (500)');
        try {
          final data = jsonDecode(response.body);
          if (data.containsKey('message')) {
            print('   Mensaje: ${data['message']}');
          }
        } catch (e) {
          print('   No se pudo parsear el error');
        }
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en test de login: $e');
      if (e.toString().contains('SocketException')) {
        print('💡 Posibles soluciones:');
        print('   - Verificar que el servidor Spring Boot esté corriendo');
        print('   - Verificar la URL: ${ApiConstants.baseUrl}');
        print(
          '   - Si usas dispositivo físico, cambiar 10.0.2.2 por la IP de tu PC',
        );
      }
    }
  }

  /// Test para verificar si el servidor Spring Boot está corriendo
  static Future<void> testSpringBootHealth() async {
    print('\n🏥 Test de Health Check de Spring Boot');

    final healthUrls = [
      '${ApiConstants.baseUrl.replaceAll('/api', '')}/actuator/health',
      '${ApiConstants.baseUrl.replaceAll('/api', '')}/health',
      ApiConstants.baseUrl,
    ];

    for (final url in healthUrls) {
      try {
        print('Probando: $url');
        final client = http.Client();
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));

        print('✅ Respuesta: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('🎉 Servidor Spring Boot está corriendo!');
          return;
        }
      } catch (e) {
        print('❌ No disponible: $e');
      }
    }

    print('❌ Servidor Spring Boot no responde en ningún endpoint');
  }
}

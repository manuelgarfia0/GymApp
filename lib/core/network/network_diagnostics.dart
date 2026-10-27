import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

/// Utilidad para diagnosticar problemas de conectividad con la API
class NetworkDiagnostics {
  static Future<void> testConnectivity() async {
    debugPrint('🔍 Iniciando diagnóstico de red...');

    // Test 1: Conectividad básica
    await _testBasicConnectivity();

    // Test 2: Endpoints específicos
    await _testApiEndpoints();
  }

  static Future<void> _testBasicConnectivity() async {
    debugPrint('\n📡 Test 1: Conectividad básica');

    try {
      final client = http.Client();

      // Probar conexión a la URL base
      debugPrint('Probando conexión a: ${ApiConstants.baseUrl}');

      final response = await client
          .get(Uri.parse(ApiConstants.baseUrl))
          .timeout(const Duration(seconds: 5));

      debugPrint('✅ Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
    } on SocketException catch (e) {
      debugPrint('❌ Error de conexión: $e');
      debugPrint('💡 Posibles causas:');
      debugPrint('   - El servidor no está corriendo');
      debugPrint('   - Firewall bloqueando la conexión');
      debugPrint('   - IP/Puerto incorrecto');
    } on TimeoutException catch (e) {
      debugPrint('⏰ Timeout: $e');
      debugPrint('💡 El servidor está tardando mucho en responder');
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
    }
  }

  static Future<void> _testApiEndpoints() async {
    debugPrint('\n🎯 Test 2: Endpoints específicos');

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
      debugPrint('\nProbando: $endpoint');

      final client = http.Client();
      final response = await client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 3));

      debugPrint('Status: ${response.statusCode}');

      if (response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          final jsonStr = json.toString();
          final maxLength = jsonStr.length > 100 ? 100 : jsonStr.length;
          debugPrint('Respuesta JSON válida: ${jsonStr.substring(0, maxLength)}...');

          // Si es un error 500, mostrar más detalles
          if (response.statusCode == 500) {
            debugPrint('🔍 Error 500 details:');
            if (json is Map && json.containsKey('message')) {
              debugPrint('   Message: ${json['message']}');
            }
            if (json is Map && json.containsKey('error')) {
              debugPrint('   Error: ${json['error']}');
            }
            if (json is Map && json.containsKey('trace')) {
              final trace = json['trace'].toString();
              final traceLength = trace.length > 200 ? 200 : trace.length;
              debugPrint('   Trace: ${trace.substring(0, traceLength)}...');
            }
          }
        } catch (e) {
          final maxLength = response.body.length > 100
              ? 100
              : response.body.length;
          debugPrint(
            'Respuesta no-JSON: ${response.body.substring(0, maxLength)}...',
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  /// Test específico para el endpoint de login
  static Future<void> testLogin(String username, String password) async {
    debugPrint('\n🔐 Test de Login');
    debugPrint('Endpoint: ${ApiConstants.loginEndpoint}');
    debugPrint('Datos: {"username": "$username", "password": "***"}');

    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('Estructura de respuesta: ${data.keys.toList()}');

          if (data.containsKey('token')) {
            final token = data['token'] as String;
            debugPrint('✅ Token recibido: ${token.substring(0, 20)}...');
          } else {
            debugPrint('❌ Token no encontrado en la respuesta');
            debugPrint('Campos disponibles: ${data.keys.toList()}');
          }
        } catch (e) {
          debugPrint('❌ Error parseando JSON: $e');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Credenciales inválidas (401)');
      } else if (response.statusCode == 403) {
        debugPrint('❌ Acceso prohibido (403) - Verificar CORS');
      } else if (response.statusCode == 500) {
        debugPrint('❌ Error del servidor (500)');
        try {
          final data = jsonDecode(response.body);
          if (data.containsKey('message')) {
            debugPrint('   Mensaje: ${data['message']}');
          }
        } catch (e) {
          debugPrint('   No se pudo parsear el error');
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en test de login: $e');
      if (e.toString().contains('SocketException')) {
        debugPrint('💡 Posibles soluciones:');
        debugPrint('   - Verificar que el servidor Spring Boot esté corriendo');
        debugPrint('   - Verificar la URL: ${ApiConstants.baseUrl}');
        debugPrint(
          '   - Si usas dispositivo físico, cambiar 10.0.2.2 por la IP de tu PC',
        );
      }
    }
  }

  /// Test para verificar si el servidor Spring Boot está corriendo
  static Future<void> testSpringBootHealth() async {
    debugPrint('\n🏥 Test de Health Check de Spring Boot');

    final healthUrls = [
      '${ApiConstants.baseUrl.replaceAll('/api', '')}/actuator/health',
      '${ApiConstants.baseUrl.replaceAll('/api', '')}/health',
      ApiConstants.baseUrl,
    ];

    for (final url in healthUrls) {
      try {
        debugPrint('Probando: $url');
        final client = http.Client();
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));

        debugPrint('✅ Respuesta: ${response.statusCode}');
        if (response.statusCode == 200) {
          debugPrint('🎉 Servidor Spring Boot está corriendo!');
          return;
        }
      } catch (e) {
        debugPrint('❌ No disponible: $e');
      }
    }

    debugPrint('❌ Servidor Spring Boot no responde en ningún endpoint');
  }
}

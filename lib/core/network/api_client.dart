import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

class ApiClient extends http.BaseClient {
  // Cliente HTTP base que hará el trabajo sucio
  final http.Client _inner = http.Client();

  // Instanciamos nuestro servicio seguro
  final SecureStorageService _storageService = SecureStorageService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Log de la petición
    print('🌐 API Request: ${request.method} ${request.url}');

    // 1. Antes de que la petición salga, leemos el token de forma segura
    final token = await _storageService.readToken();

    // 2. Si el token existe, inyectamos el header de Authorization (estilo Bearer)
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      print('🔑 API Request: Token added (${token.substring(0, 20)}...)');
    } else {
      print('⚠️ API Request: No token found');
    }

    // 3. Ya de paso, le decimos que todas nuestras peticiones son en JSON
    // (Así no tienes que poner esto a mano nunca más tampoco)
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    try {
      // 4. Dejamos que la petición continúe su viaje hacia Spring Boot
      final response = await _inner.send(request);
      print('🌐 API Response: ${response.statusCode} for ${request.url}');
      return response;
    } catch (e) {
      print('❌ API Error: $e for ${request.url}');
      rethrow;
    }
  }

  /// Override del método post para asegurar manejo correcto de Content-Type para JSON
  ///
  /// El paquete http puede sobrescribir el Content-Type configurado en send(),
  /// especialmente cuando se pasa un String como body. Este override asegura
  /// que las peticiones POST con cuerpo JSON mantengan el Content-Type correcto.
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
  /// Verifica si el body es un String que parece ser JSON válido
  /// o si ya es un objeto que será serializado como JSON.
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

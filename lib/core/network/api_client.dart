// lib/core/network/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

/// Cliente HTTP autenticado que inyecta el token JWT en cada petición.
///
/// Extiende [http.BaseClient] para interceptar todas las peticiones
/// salientes y añadir el header de [Authorization] de forma transparente.
///
/// IMPORTANTE: Los métodos [post], [put] y [patch] están sobreescritos para
/// garantizar que el header [Content-Type: application/json] se establece
/// ANTES de que el paquete http procese el cuerpo. Sin este override, cuando
/// el body es un [String] el paquete http puede establecer Content-Type como
/// text/plain y la comprobación en [send] llega demasiado tarde.
class ApiClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final SecureStorageService _storageService;

  ApiClient(this._storageService);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('🌐 API Request: ${request.method} ${request.url}');

    final token = await _storageService.readToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      print('🔑 Token añadido (${token.substring(0, 20)}...)');
    } else {
      print('⚠️ No se encontró token');
    }

    // Fallback: si aún no hay Content-Type lo ponemos aquí.
    // Para POST/PUT/PATCH con body JSON los overrides de abajo ya lo fuerzan.
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    try {
      final response = await _inner.send(request);
      print('🌐 API Response: ${response.statusCode} — ${request.url}');
      return response;
    } catch (e) {
      print('❌ API Error: $e — ${request.url}');
      rethrow;
    }
  }

  // ── Method overrides ──────────────────────────────────────────────────────
  // Pasamos Content-Type explícitamente en los headers para que llegue al
  // servidor correcto independientemente de cómo el paquete http serialice
  // el body antes de llamar a send().

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => super.post(
    url,
    headers: _jsonHeaders(headers),
    body: body,
    encoding: encoding,
  );

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => super.put(
    url,
    headers: _jsonHeaders(headers),
    body: body,
    encoding: encoding,
  );

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => super.patch(
    url,
    headers: _jsonHeaders(headers),
    body: body,
    encoding: encoding,
  );

  /// Combina los headers del caller con Content-Type: application/json,
  /// dando prioridad a los headers del caller si coinciden en clave.
  Map<String, String> _jsonHeaders(Map<String, String>? extra) => {
    'Content-Type': 'application/json',
    ...?extra,
  };
}

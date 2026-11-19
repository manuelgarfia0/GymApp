// lib/core/network/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';
import 'api_constants.dart';

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
  static const Duration _defaultTimeout = Duration(seconds: 8);
  static const Duration _remoteTimeout = Duration(seconds: 120);
  static const Duration _probeTimeout = Duration(seconds: 5);

  final http.Client _inner = http.Client();
  final SecureStorageService _storageService;

  ApiClient(this._storageService);

  /// Envía un ping ligero en segundo plano al backend remoto para iniciar
  /// su despertar en frío sin bloquear ni lanzar errores hacia la UI.
  Future<void> warmUpServer() async {
    if (!ApiConstants.hasExplicitBaseUrl) return;
    try {
      await _inner
          .get(Uri.parse(ApiConstants.pingEndpoint))
          .timeout(_remoteTimeout);
    } catch (_) {
      // Silencioso por diseño: solo intenta despertar el servidor remoto.
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    debugPrint('🌐 API Request: ${request.method} ${request.url}');
    await _prepareHeaders(request);

    final canFallbackAndroid =
        ApiConstants.isUsingAndroidFallback &&
        request is http.Request &&
        request.url.toString().startsWith(ApiConstants.baseUrl);

    if (canFallbackAndroid) {
      if (!ApiConstants.hasResolvedBaseUrl) {
        return _sendWithAndroidFallback(request);
      }
      try {
        return await _sendSingle(_cloneRequest(request, request.url));
      } catch (e) {
        if (!_isConnectivityError(e)) rethrow;
        ApiConstants.resetResolvedBaseUrl();
        return _sendWithAndroidFallback(request);
      }
    }

    return _sendSingle(request);
  }

  bool _isConnectivityError(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException;

  Future<void> _prepareHeaders(http.BaseRequest request) async {
    final token = await _storageService.readToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      debugPrint(
        '🔑 Token añadido (${token.substring(0, token.length > 20 ? 20 : token.length)}...)',
      );
    } else {
      debugPrint('⚠️ No se encontró token');
    }

    // Fallback: si aún no hay Content-Type lo ponemos aquí.
    // Para POST/PUT/PATCH con body JSON los overrides de abajo ya lo fuerzan.
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }
  }

  Future<http.StreamedResponse> _sendSingle(http.BaseRequest request) async {
    final timeout = ApiConstants.hasExplicitBaseUrl
        ? _remoteTimeout
        : _defaultTimeout;
    try {
      final response = await _inner.send(request).timeout(timeout);
      debugPrint('🌐 API Response: ${response.statusCode} — ${request.url}');
      return response;
    } on SocketException catch (e) {
      _handleConnectivityFailure(e, request.url);
      rethrow;
    } on TimeoutException catch (e) {
      _handleConnectivityFailure(e, request.url);
      rethrow;
    } on http.ClientException catch (e) {
      _handleConnectivityFailure(e, request.url);
      rethrow;
    } catch (e) {
      debugPrint('❌ API Error: $e — ${request.url}');
      rethrow;
    }
  }

  Future<http.StreamedResponse> _sendWithAndroidFallback(
    http.Request original,
  ) async {
    final suffix = original.url.toString().substring(ApiConstants.baseUrl.length);
    Object? lastError;

    for (final candidateBaseUrl in ApiConstants.androidFallbackBaseUrls) {
      final targetUri = Uri.parse('$candidateBaseUrl$suffix');
      final attempt = _cloneRequest(original, targetUri);

      try {
        debugPrint('🔍 ApiClient: Probando servidor $targetUri');
        final response = await _inner.send(attempt).timeout(_probeTimeout);
        ApiConstants.setResolvedBaseUrl(candidateBaseUrl);
        debugPrint(
          '✅ ApiClient: Conectado a $candidateBaseUrl (${response.statusCode})',
        );
        return response;
      } on SocketException catch (e) {
        debugPrint('⚠️ ApiClient: No accesible $candidateBaseUrl ($e)');
        lastError = e;
      } on TimeoutException catch (e) {
        debugPrint('⏰ ApiClient: Timeout en $candidateBaseUrl ($e)');
        lastError = e;
      } on http.ClientException catch (e) {
        debugPrint('⚠️ ApiClient: Error HTTP en $candidateBaseUrl ($e)');
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw const SocketException(
      'No se pudo conectar con ningún servidor de la API.',
    );
  }

  http.Request _cloneRequest(http.Request original, Uri targetUrl) {
    final clone = http.Request(original.method, targetUrl)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..bodyBytes = original.bodyBytes;
    return clone;
  }

  void _handleConnectivityFailure(Object error, Uri url) {
    debugPrint('❌ API Error: $error — $url');
    if (ApiConstants.isUsingAndroidFallback) {
      ApiConstants.resetResolvedBaseUrl();
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

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => super.delete(
    url,
    headers: body != null ? _jsonHeaders(headers) : headers,
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

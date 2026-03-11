// Archivo: lib/core/network/api_client.dart

import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

class ApiClient extends http.BaseClient {
  // Cliente HTTP base que hará el trabajo sucio
  final http.Client _inner = http.Client();

  // Instanciamos nuestro servicio seguro
  final SecureStorageService _storageService = SecureStorageService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Antes de que la petición salga, leemos el token de forma segura
    final token = await _storageService.readToken();

    // 2. Si el token existe, inyectamos el header de Authorization (estilo Bearer)
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Ya de paso, le decimos que todas nuestras peticiones son en JSON
    // (Así no tienes que poner esto a mano nunca más tampoco)
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    // 4. Dejamos que la petición continúe su viaje hacia Spring Boot
    return _inner.send(request);
  }
}

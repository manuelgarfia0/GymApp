// Archivo: lib/core/storage/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Instancia de la librería con configuraciones por defecto
  final _storage = const FlutterSecureStorage();

  final String _tokenKey = 'jwt_token';

  // Guardar el token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Leer el token
  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Borrar el token (Para cuando el usuario haga Logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

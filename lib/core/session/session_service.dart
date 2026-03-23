import 'package:jwt_decoder/jwt_decoder.dart';
import '../storage/secure_storage_service.dart';

/// Servicio de sesión de usuario.
///
/// Fuente única de verdad para el ID del usuario autenticado.
/// Extrae el [userId] directamente del JWT almacenado en [SecureStorageService],
/// eliminando la necesidad de duplicar este dato en [SharedPreferences]
/// y evitando posibles desincronizaciones entre ambas fuentes.
class SessionService {
  final SecureStorageService _storageService;

  const SessionService(this._storageService);

  /// Retorna el ID del usuario de la sesión activa.
  ///
  /// Devuelve [null] si:
  /// - No existe token almacenado.
  /// - El token está expirado.
  /// - El token no contiene el claim 'id'.
  /// - Ocurre cualquier error al decodificar.
  Future<int?> getUserId() async {
    try {
      final token = await _storageService.readToken();
      if (token == null || token.isEmpty) return null;
      if (JwtDecoder.isExpired(token)) return null;

      final claims = JwtDecoder.decode(token);
      final id = claims['id'];
      if (id == null) return null;

      return (id as num).toInt();
    } catch (_) {
      return null;
    }
  }

  /// Verifica si existe una sesión activa con token válido y no expirado.
  Future<bool> hasValidSession() async {
    try {
      final token = await _storageService.readToken();
      if (token == null || token.isEmpty) return false;
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }
}

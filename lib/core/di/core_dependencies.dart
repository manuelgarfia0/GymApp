import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Infraestructura compartida entre todos los features.
///
/// Garantiza una única instancia de [ApiClient] y [SecureStorageService]
/// en toda la app. Cada feature *Dependencies debe obtener sus dependencias
/// de aquí en lugar de instanciarlas de forma independiente.
///
/// Esto elimina el anti-patrón de tener 3 HttpClients separados
/// (AuthDependencies, WorkoutDependencies, ProfileDependencies).
class CoreDependencies {
  static ApiClient? _apiClient;
  static SecureStorageService? _storageService;

  /// Instancia compartida del cliente HTTP autenticado.
  static ApiClient get apiClient {
    _apiClient ??= ApiClient();
    return _apiClient!;
  }

  /// Instancia compartida del servicio de almacenamiento seguro.
  static SecureStorageService get storageService {
    _storageService ??= SecureStorageService();
    return _storageService!;
  }

  /// Resetea todas las dependencias core.
  /// Útil en tests y en el logout del usuario.
  static void reset() {
    _apiClient = null;
    _storageService = null;
  }
}

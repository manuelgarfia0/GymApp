// lib/core/di/core_dependencies.dart

import '../network/api_client.dart';
import '../services/app_permissions_service.dart';
import '../session/session_service.dart';
import '../settings/app_settings_service.dart';
import '../storage/secure_storage_service.dart';

/// Infraestructura compartida entre todos los features.
///
/// Garantiza una única instancia de [ApiClient], [SecureStorageService]
/// y [SessionService] en toda la app.
///
/// Cada feature *Dependencies debe obtener sus dependencias
/// de aquí en lugar de instanciarlas de forma independiente.
class CoreDependencies {
  static ApiClient? _apiClient;
  static SecureStorageService? _storageService;
  static SessionService? _sessionService;
  static AppPermissionsService? _permissionsService;
  static AppSettingsService? _settingsService;

  /// Instancia compartida del servicio de almacenamiento seguro.
  static SecureStorageService get storageService {
    _storageService ??= SecureStorageService();
    return _storageService!;
  }

  /// Instancia compartida del cliente HTTP autenticado.
  ///
  /// Recibe [storageService] por constructor injection para garantizar
  /// que se usa la misma instancia de [FlutterSecureStorage] en toda la app,
  /// evitando el anti-patrón de múltiples instancias descoordinadas.
  static ApiClient get apiClient {
    _apiClient ??= ApiClient(storageService);
    return _apiClient!;
  }

  /// Fuente única de verdad para el ID del usuario autenticado.
  ///
  /// Extrae el userId del JWT en lugar de depender de [SharedPreferences],
  /// eliminando posibles desincronizaciones entre ambas fuentes.
  static SessionService get sessionService {
    _sessionService ??= SessionService(storageService);
    return _sessionService!;
  }

  /// Servicio centralizado de solicitud de permisos en tiempo de ejecución.
  static AppPermissionsService get permissionsService {
    _permissionsService ??= AppPermissionsService();
    return _permissionsService!;
  }

  /// Servicio reactivo de configuración global persistida localmente.
  static AppSettingsService get settingsService {
    _settingsService ??= AppSettingsService();
    return _settingsService!;
  }

  /// Resetea todas las dependencias core.
  /// Útil en tests y en el logout del usuario.
  static void reset() {
    _apiClient = null;
    _storageService = null;
    _sessionService = null;
    _permissionsService = null;
    _settingsService?.resetInMemory();
    _settingsService = null;
  }
}

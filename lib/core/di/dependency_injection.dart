import '../../features/auth/auth_dependencies.dart';
import '../../features/profile/profile_dependencies.dart';
import '../../features/workouts/workout_dependencies.dart';
import 'core_dependencies.dart';

/// Contenedor global de inyección de dependencias.
/// Coordina todos los factories de features y la infraestructura compartida.
class DependencyInjection {
  static bool _isInitialized = false;

  /// Inicializa todas las dependencias.
  /// Debe llamarse una única vez en el arranque de la app.
  static void initialize() {
    if (_isInitialized) return;
    // CoreDependencies provee ApiClient y SecureStorageService compartidos.
    // Los features *Dependencies obtienen sus instancias de CoreDependencies.
    _isInitialized = true;
  }

  /// Resetea todas las dependencias.
  /// Útil en tests, hot reload y tras un logout.
  static void reset() {
    CoreDependencies.reset();
    AuthDependencies.reset();
    WorkoutDependencies.reset();
    ProfileDependencies.reset();
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
}

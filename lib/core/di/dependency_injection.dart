import '../../features/auth/auth_dependencies.dart';
import '../../features/profile/profile_dependencies.dart';
import '../../features/workouts/workout_dependencies.dart';

/// Global dependency injection container
/// Coordinates all feature-specific dependency factories
/// Follows clean architecture principles with proper layer separation
class DependencyInjection {
  static bool _isInitialized = false;

  /// Initialize all dependencies
  /// Should be called once at app startup
  static void initialize() {
    if (_isInitialized) return;

    // Dependencies are lazily initialized by each feature's factory
    // No explicit initialization needed due to singleton pattern

    _isInitialized = true;
  }

  /// Reset all dependencies
  /// Useful for testing and hot reload scenarios
  static void reset() {
    AuthDependencies.reset();
    WorkoutDependencies.reset();
    ProfileDependencies.reset();
    _isInitialized = false;
  }

  /// Check if dependencies are initialized
  static bool get isInitialized => _isInitialized;
}

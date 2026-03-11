import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para obtener el historial de entrenamientos.
/// Encapsula la lógica de negocio para obtener datos de entrenamientos.
class GetWorkoutHistory {
  final WorkoutRepository _repository;

  GetWorkoutHistory(this._repository);

  /// Obtiene todos los entrenamientos completados para el usuario especificado.
  ///
  /// [userId] El ID del usuario cuyo historial de entrenamientos obtener.
  ///
  /// Retorna una lista de entidades Workout pertenecientes al usuario, ordenadas por fecha (más recientes primero).
  /// Retorna una lista vacía si no se encuentran entrenamientos.
  /// Lanza una excepción si la operación falla.
  Future<List<Workout>> call(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }

    final workouts = await _repository.getUserWorkouts(userId);

    // Ordenar entrenamientos por hora de inicio, más recientes primero
    workouts.sort((a, b) => b.startTime.compareTo(a.startTime));

    return workouts;
  }

  /// Obtiene un entrenamiento específico por su ID.
  ///
  /// [workoutId] El ID del entrenamiento a obtener.
  ///
  /// Retorna la entidad Workout si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Workout?> getById(int workoutId) async {
    if (workoutId <= 0) {
      throw ArgumentError('Valid workout ID is required');
    }

    return await _repository.getWorkoutById(workoutId);
  }

  /// Obtiene el entrenamiento activo actual para un usuario (si existe).
  ///
  /// [userId] El ID del usuario.
  ///
  /// Retorna la entidad Workout activa si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Workout?> getActiveWorkout(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }

    return await _repository.getActiveWorkout(userId);
  }

  /// Finaliza un entrenamiento activo estableciendo la hora de finalización.
  ///
  /// [workoutId] El ID del entrenamiento a finalizar.
  ///
  /// Retorna la entidad Workout completada.
  /// Lanza una excepción si la operación falla o el entrenamiento no existe.
  Future<Workout> endWorkout(int workoutId) async {
    if (workoutId <= 0) {
      throw ArgumentError('Valid workout ID is required');
    }

    return await _repository.endWorkout(workoutId);
  }

  /// Obtiene estadísticas de entrenamientos para un usuario.
  ///
  /// [userId] El ID del usuario.
  ///
  /// Retorna un mapa conteniendo estadísticas de entrenamientos.
  Future<Map<String, dynamic>> getWorkoutStats(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }

    final workouts = await call(userId);
    final completedWorkouts = workouts.where((w) => !w.isActive).toList();

    if (completedWorkouts.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalSets': 0,
        'totalReps': 0,
        'totalWeight': 0.0,
        'averageDuration': Duration.zero,
      };
    }

    final totalSets = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + w.sets.length,
    );
    final totalReps = completedWorkouts.fold<int>(
      0,
      (sum, w) => sum + w.sets.fold<int>(0, (setSum, s) => setSum + s.reps),
    );
    final totalWeight = completedWorkouts.fold<double>(
      0.0,
      (sum, w) =>
          sum +
          w.sets.fold<double>(0.0, (setSum, s) => setSum + (s.weight * s.reps)),
    );

    final totalDuration = completedWorkouts.fold<Duration>(
      Duration.zero,
      (sum, w) => sum + w.duration,
    );
    final averageDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ completedWorkouts.length,
    );

    return {
      'totalWorkouts': completedWorkouts.length,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalWeight': totalWeight,
      'averageDuration': averageDuration,
    };
  }
}

import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para obtener el historial de entrenamientos.
/// CORRECCIÓN: eliminado el método getActiveWorkout porque el endpoint
/// GET /api/workouts/active ya no existe en el backend.
class GetWorkoutHistory {
  final WorkoutRepository _repository;

  GetWorkoutHistory(this._repository);

  Future<List<Workout>> call(int userId) async {
    if (userId <= 0) throw ArgumentError('Valid user ID is required');

    final workouts = await _repository.getUserWorkouts(userId);
    // El backend ya ordena por startTime DESC, pero lo aseguramos aquí
    workouts.sort((a, b) => b.startTime.compareTo(a.startTime));
    return workouts;
  }

  Future<Workout?> getById(int workoutId) async {
    if (workoutId <= 0) throw ArgumentError('Valid workout ID is required');
    return await _repository.getWorkoutById(workoutId);
  }

  /// Finaliza un entrenamiento activo.
  /// Llama a PATCH /api/workouts/{id}/end — este endpoint SÍ existe en el backend.
  Future<Workout> endWorkout(int workoutId) async {
    if (workoutId <= 0) throw ArgumentError('Valid workout ID is required');
    return await _repository.endWorkout(workoutId);
  }

  Future<Map<String, dynamic>> getWorkoutStats(int userId) async {
    if (userId <= 0) throw ArgumentError('Valid user ID is required');

    final workouts = await call(userId);
    final completed = workouts.where((w) => !w.isActive).toList();

    if (completed.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalSets': 0,
        'totalReps': 0,
        'totalWeight': 0.0,
        'averageDuration': Duration.zero,
      };
    }

    final totalSets = completed.fold<int>(0, (sum, w) => sum + w.sets.length);
    final totalReps = completed.fold<int>(
      0,
      (sum, w) => sum + w.sets.fold<int>(0, (s, set) => s + set.reps),
    );
    final totalWeight = completed.fold<double>(
      0.0,
      (sum, w) =>
          sum +
          w.sets.fold<double>(0.0, (s, set) => s + (set.weight * set.reps)),
    );
    final totalDuration = completed.fold<Duration>(
      Duration.zero,
      (sum, w) => sum + w.duration,
    );
    final avgDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ completed.length,
    );

    return {
      'totalWorkouts': completed.length,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalWeight': totalWeight,
      'averageDuration': avgDuration,
    };
  }
}

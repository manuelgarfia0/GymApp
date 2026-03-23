// lib/features/workouts/domain/use_cases/get_workout_history.dart

import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para obtener el historial de entrenamientos.
class GetWorkoutHistory {
  final WorkoutRepository _repository;

  GetWorkoutHistory(this._repository);

  /// Devuelve todos los workouts del usuario ordenados por fecha descendente.
  Future<List<Workout>> call(int userId) async {
    if (userId <= 0) throw ArgumentError('Valid user ID is required');

    final workouts = await _repository.getUserWorkouts(userId);
    workouts.sort((a, b) => b.startTime.compareTo(a.startTime));
    return workouts;
  }

  Future<Workout?> getById(int workoutId) async {
    if (workoutId <= 0) throw ArgumentError('Valid workout ID is required');
    return await _repository.getWorkoutById(workoutId);
  }

  /// Devuelve el último workout completado que usó [routineId] como base.
  ///
  /// Sirve para pre-poblar [ActiveWorkoutScreen] con los pesos y repeticiones
  /// reales de la sesión anterior, de modo que el usuario no tenga que
  /// introducirlos de nuevo cada vez que inicia la misma rutina.
  ///
  /// Devuelve [null] si el usuario nunca ha entrenado con esa rutina.
  Future<Workout?> getLastWorkoutForRoutine(int userId, int routineId) async {
    if (userId <= 0) throw ArgumentError('Valid user ID is required');
    if (routineId <= 0) throw ArgumentError('Valid routine ID is required');

    final workouts = await call(userId);

    // El listado ya viene ordenado por fecha desc; el primero que coincida
    // con el routineId es el más reciente.
    try {
      return workouts.firstWhere(
        (w) => w.routineId == routineId && w.endTime != null,
      );
    } catch (_) {
      return null;
    }
  }

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

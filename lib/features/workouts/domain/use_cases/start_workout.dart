import '../entities/workout.dart';
import '../repositories/workout_repository.dart';
import '../repositories/routine_repository.dart';

/// Caso de uso para iniciar una sesión de entrenamiento.
/// CORRECCIÓN: eliminada la comprobación de getActiveWorkout porque el endpoint
/// GET /api/workouts/active ya no existe en el backend.
class StartWorkout {
  final WorkoutRepository _workoutRepository;
  final RoutineRepository _routineRepository;

  StartWorkout(this._workoutRepository, this._routineRepository);

  /// Inicia un entrenamiento basado en una rutina existente.
  Future<Workout> fromRoutine(
    int userId,
    int routineId, {
    String? workoutName,
  }) async {
    if (userId <= 0) throw ArgumentError('Valid user ID is required');
    if (routineId <= 0) throw ArgumentError('Valid routine ID is required');

    final routine = await _routineRepository.getRoutineById(routineId);
    if (routine == null) throw ArgumentError('Routine not found');

    final workout = Workout(
      name: workoutName ?? routine.name,
      startTime: DateTime.now(),
      userId: userId,
      routineId: routineId,
      sets: [],
    );

    return await _workoutRepository.createWorkout(workout);
  }

  /// Inicia un entrenamiento libre (sin rutina base).
  Future<Workout> freeForm(int userId, String workoutName) async {
    if (userId <= 0) throw ArgumentError('Valid user ID is required');
    if (workoutName.trim().isEmpty) {
      throw ArgumentError('Workout name cannot be empty');
    }

    final workout = Workout(
      name: workoutName.trim(),
      startTime: DateTime.now(),
      userId: userId,
      sets: [],
    );

    return await _workoutRepository.createWorkout(workout);
  }
}

import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para guardar un entrenamiento completado.
/// CORRECCIÓN: usa repository.createWorkout() en lugar del eliminado saveWorkout().
/// El backend acepta un workout con endTime ya incluida en POST /api/workouts.
class SaveWorkout {
  final WorkoutRepository _repository;

  SaveWorkout(this._repository);

  Future<bool> call(Workout workout) async {
    _validateWorkout(workout);
    // createWorkout devuelve el Workout creado; si no lanza excepción, fue exitoso
    await _repository.createWorkout(workout);
    return true;
  }

  void _validateWorkout(Workout workout) {
    if (workout.name.trim().isEmpty) {
      throw ArgumentError('Workout name cannot be empty');
    }
    if (workout.userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }
    if (workout.sets.isEmpty) {
      throw ArgumentError('Workout must contain at least one set');
    }
    if (workout.endTime == null) {
      throw ArgumentError('Workout must have an end time to be saved');
    }
    if (workout.endTime!.isBefore(workout.startTime)) {
      throw ArgumentError('Workout end time cannot be before start time');
    }
    for (final set in workout.sets) {
      if (set.exerciseId <= 0) {
        throw ArgumentError('Valid exercise ID is required for all sets');
      }
      if (set.weight < 0) throw ArgumentError('Weight cannot be negative');
      if (set.reps <= 0) throw ArgumentError('Reps must be greater than 0');
      if (set.setNumber <= 0) {
        throw ArgumentError('Set number must be greater than 0');
      }
      if (set.exerciseOrder <= 0) {
        throw ArgumentError('Exercise order must be greater than 0');
      }
    }
  }
}

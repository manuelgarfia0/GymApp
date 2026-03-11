import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para guardar un entrenamiento completado.
/// Encapsula la lógica de negocio para la finalización y persistencia de entrenamientos.
class SaveWorkout {
  final WorkoutRepository _repository;

  SaveWorkout(this._repository);

  /// Guarda un entrenamiento completado con todas sus series.
  ///
  /// [workout] La entidad de entrenamiento a guardar.
  ///
  /// Retorna true si el guardado fue exitoso.
  /// Lanza una excepción si la validación falla o la operación falla.
  Future<bool> call(Workout workout) async {
    // Validar datos del entrenamiento
    _validateWorkout(workout);

    // Guardar el entrenamiento a través del repositorio
    return await _repository.saveWorkout(workout);
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

    // Validate each set in the workout
    for (final set in workout.sets) {
      if (set.exerciseId <= 0) {
        throw ArgumentError('Valid exercise ID is required for all sets');
      }
      if (set.weight < 0) {
        throw ArgumentError('Weight cannot be negative');
      }
      if (set.reps <= 0) {
        throw ArgumentError('Reps must be greater than 0');
      }
      if (set.setNumber <= 0) {
        throw ArgumentError('Set number must be greater than 0');
      }
      if (set.exerciseOrder <= 0) {
        throw ArgumentError('Exercise order must be greater than 0');
      }
    }
  }
}

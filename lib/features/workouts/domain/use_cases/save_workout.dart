import '../../../../core/errors/failures.dart';
import '../../workout_dependencies.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para guardar un entrenamiento completado.
class SaveWorkout {
  final WorkoutRepository _repository;

  SaveWorkout(this._repository);

  Future<bool> call(Workout workout) async {
    _validateWorkout(workout);
    await _repository.createWorkout(workout);
    WorkoutDependencies.notifyWorkoutSaved();
    return true;
  }

  void _validateWorkout(Workout workout) {
    if (workout.name.trim().isEmpty) {
      throw const ValidationFailure('El nombre del entrenamiento no puede estar vacío');
    }
    if (workout.userId <= 0) {
      throw const ValidationFailure('Se requiere un ID de usuario válido');
    }
    if (workout.sets.isEmpty) {
      throw const ValidationFailure('El entrenamiento debe contener al menos una serie');
    }
    if (workout.endTime == null) {
      throw const ValidationFailure('El entrenamiento debe tener una hora de finalización');
    }
    if (workout.endTime!.isBefore(workout.startTime)) {
      throw const ValidationFailure('La hora de fin no puede ser anterior a la hora de inicio');
    }
    for (final set in workout.sets) {
      if (set.exerciseId <= 0) {
        throw const ValidationFailure('Cada serie debe tener un ejercicio válido asignado');
      }
      if (set.weight < 0) {
        throw const ValidationFailure('El peso no puede ser negativo');
      }
      if (set.reps <= 0) {
        throw const ValidationFailure('Las repeticiones deben ser mayores a 0');
      }
      if (set.setNumber <= 0) {
        throw const ValidationFailure('El número de serie debe ser mayor a 0');
      }
      if (set.exerciseOrder <= 0) {
        throw const ValidationFailure('El orden del ejercicio debe ser mayor a 0');
      }
    }
  }
}

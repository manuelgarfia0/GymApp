import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

/// Caso de uso para registrar series de ejercicios durante un entrenamiento.
/// Encapsula la lógica de negocio para el registro de ejercicios.
class LogExercise {
  final WorkoutRepository _repository;

  LogExercise(this._repository);

  /// Registra una serie para un ejercicio en el entrenamiento activo.
  ///
  /// [workoutId] El ID del entrenamiento activo.
  /// [exerciseId] El ID del ejercicio que se está realizando.
  /// [exerciseName] El nombre del ejercicio (opcional, para propósitos de visualización).
  /// [exerciseOrder] El orden del ejercicio en el entrenamiento.
  /// [setNumber] El número de serie para este ejercicio.
  /// [weight] El peso usado para esta serie.
  /// [reps] El número de repeticiones realizadas.
  /// [notes] Notas opcionales para esta serie.
  ///
  /// Retorna la entidad Workout actualizada con la nueva serie agregada.
  /// Lanza una excepción si la validación falla o la operación falla.
  Future<Workout> logSet({
    required int workoutId,
    required int exerciseId,
    String? exerciseName,
    required int exerciseOrder,
    required int setNumber,
    required double weight,
    required int reps,
    String? notes,
  }) async {
    // Validar parámetros de entrada
    if (workoutId <= 0) {
      throw ArgumentError('Valid workout ID is required');
    }
    if (exerciseId <= 0) {
      throw ArgumentError('Valid exercise ID is required');
    }
    if (exerciseOrder <= 0) {
      throw ArgumentError('Exercise order must be greater than 0');
    }
    if (setNumber <= 0) {
      throw ArgumentError('Set number must be greater than 0');
    }
    if (weight < 0) {
      throw ArgumentError('Weight cannot be negative');
    }
    if (reps <= 0) {
      throw ArgumentError('Reps must be greater than 0');
    }

    // Obtener el entrenamiento actual
    final workout = await _repository.getWorkoutById(workoutId);
    if (workout == null) {
      throw ArgumentError('Workout not found');
    }

    // Verificar si el entrenamiento sigue activo
    if (!workout.isActive) {
      throw StateError('Cannot log exercises to a completed workout');
    }

    // Crear la nueva serie de entrenamiento
    final newSet = WorkoutSet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseOrder: exerciseOrder,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      timestamp: DateTime.now(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );

    // Agregar la serie al entrenamiento
    final updatedSets = List<WorkoutSet>.from(workout.sets)..add(newSet);

    final updatedWorkout = Workout(
      id: workout.id,
      name: workout.name,
      startTime: workout.startTime,
      endTime: workout.endTime,
      userId: workout.userId,
      routineId: workout.routineId,
      sets: updatedSets,
    );

    return await _repository.updateWorkout(updatedWorkout);
  }

  /// Obtiene el siguiente número de serie para un ejercicio en el entrenamiento.
  ///
  /// [workout] El entrenamiento actual.
  /// [exerciseId] El ID del ejercicio.
  ///
  /// Retorna el siguiente número de serie para el ejercicio.
  int getNextSetNumber(Workout workout, int exerciseId) {
    final exerciseSets = workout.sets.where(
      (set) => set.exerciseId == exerciseId,
    );
    if (exerciseSets.isEmpty) {
      return 1;
    }
    return exerciseSets
            .map((set) => set.setNumber)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  /// Obtiene el siguiente orden de ejercicio para el entrenamiento.
  ///
  /// [workout] El entrenamiento actual.
  ///
  /// Retorna el siguiente número de orden de ejercicio.
  int getNextExerciseOrder(Workout workout) {
    if (workout.sets.isEmpty) {
      return 1;
    }
    return workout.sets
            .map((set) => set.exerciseOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }
}

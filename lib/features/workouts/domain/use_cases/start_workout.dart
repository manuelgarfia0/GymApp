import '../entities/workout.dart';
import '../repositories/workout_repository.dart';
import '../repositories/routine_repository.dart';

/// Caso de uso para iniciar una nueva sesión de entrenamiento.
/// Encapsula la lógica de negocio para la iniciación de entrenamientos.
class StartWorkout {
  final WorkoutRepository _workoutRepository;
  final RoutineRepository _routineRepository;

  StartWorkout(this._workoutRepository, this._routineRepository);

  /// Inicia una nueva sesión de entrenamiento basada en una rutina.
  ///
  /// [userId] El ID del usuario que inicia el entrenamiento.
  /// [routineId] El ID de la rutina en la que basar el entrenamiento.
  /// [workoutName] Nombre personalizado opcional para el entrenamiento.
  ///
  /// Retorna la entidad Workout creada.
  /// Lanza una excepción si la validación falla o la operación falla.
  Future<Workout> fromRoutine(
    int userId,
    int routineId, {
    String? workoutName,
  }) async {
    if (userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }
    if (routineId <= 0) {
      throw ArgumentError('Valid routine ID is required');
    }

    // Verificar si el usuario ya tiene un entrenamiento activo
    final activeWorkout = await _workoutRepository.getActiveWorkout(userId);
    if (activeWorkout != null) {
      throw StateError(
        'User already has an active workout. Please finish the current workout first.',
      );
    }

    // Obtener la rutina en la que basar el entrenamiento
    final routine = await _routineRepository.getRoutineById(routineId);
    if (routine == null) {
      throw ArgumentError('Routine not found');
    }

    // Crear el entrenamiento
    final workout = Workout(
      name: workoutName ?? routine.name,
      startTime: DateTime.now(),
      userId: userId,
      routineId: routineId,
      sets:
          [], // Lista de series vacía - se poblará cuando el usuario registre ejercicios
    );

    return await _workoutRepository.createWorkout(workout);
  }

  /// Inicia un nuevo entrenamiento libre (no basado en una rutina).
  ///
  /// [userId] El ID del usuario que inicia el entrenamiento.
  /// [workoutName] El nombre para el entrenamiento.
  ///
  /// Retorna la entidad Workout creada.
  /// Lanza una excepción si la validación falla o la operación falla.
  Future<Workout> freeForm(int userId, String workoutName) async {
    if (userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }
    if (workoutName.trim().isEmpty) {
      throw ArgumentError('Workout name cannot be empty');
    }

    // Verificar si el usuario ya tiene un entrenamiento activo
    final activeWorkout = await _workoutRepository.getActiveWorkout(userId);
    if (activeWorkout != null) {
      throw StateError(
        'User already has an active workout. Please finish the current workout first.',
      );
    }

    // Crear el entrenamiento
    final workout = Workout(
      name: workoutName.trim(),
      startTime: DateTime.now(),
      userId: userId,
      sets:
          [], // Lista de series vacía - se poblará cuando el usuario registre ejercicios
    );

    return await _workoutRepository.createWorkout(workout);
  }
}

import '../entities/workout.dart';

/// Interfaz de repositorio para operaciones de workouts.
/// Eliminados: saveWorkout (llamaba a endpoint borrado) y getActiveWorkout (idem).
abstract class WorkoutRepository {
  Future<List<Workout>> getUserWorkouts(int userId);
  Future<Workout?> getWorkoutById(int id);

  /// Crea un workout nuevo. Se usa tanto para iniciar como para guardar
  /// un entrenamiento completo (con endTime ya incluida).
  Future<Workout> createWorkout(Workout workout);

  Future<Workout> updateWorkout(Workout workout);

  /// Finaliza un workout activo: llama a PATCH /api/workouts/{id}/end
  /// El backend setea endTime = LocalDateTime.now()
  Future<Workout> endWorkout(int workoutId);
}

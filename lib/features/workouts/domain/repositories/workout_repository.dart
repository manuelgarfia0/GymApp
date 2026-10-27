import '../entities/workout.dart';

/// Interfaz de repositorio para operaciones de workouts.
/// Soporta ciclo completo CRUD y finalización de entrenamientos.
abstract class WorkoutRepository {
  Future<List<Workout>> getUserWorkouts(int userId);
  Future<Workout?> getWorkoutById(int id);

  /// Crea un workout nuevo. Se usa tanto para iniciar como para guardar
  /// un entrenamiento completo (con endTime ya incluida).
  Future<Workout> createWorkout(Workout workout);

  Future<Workout> updateWorkout(Workout workout);

  /// Elimina un workout existente.
  Future<bool> deleteWorkout(int id);

  /// Finaliza un workout activo: llama a PATCH /api/workouts/{id}/end
  /// El backend setea endTime = LocalDateTime.now()
  Future<Workout> endWorkout(int workoutId);
}

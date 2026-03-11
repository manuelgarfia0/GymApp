import '../entities/workout.dart';

/// Interfaz de repositorio para operaciones de datos de entrenamientos.
/// Define el contrato para el acceso a datos de entrenamientos sin detalles de implementación.
/// Esta interfaz será implementada en la capa de datos.
abstract class WorkoutRepository {
  /// Obtiene todos los entrenamientos para un usuario específico.
  /// Retorna una lista de entidades Workout pertenecientes al usuario.
  /// Lanza una excepción si la operación falla.
  Future<List<Workout>> getUserWorkouts(int userId);

  /// Obtiene un entrenamiento específico por su ID.
  /// Retorna la entidad Workout si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Workout?> getWorkoutById(int id);

  /// Crea una nueva sesión de entrenamiento.
  /// Retorna la entidad Workout creada con ID asignado.
  /// Lanza una excepción si la operación falla.
  Future<Workout> createWorkout(Workout workout);

  /// Actualiza un entrenamiento existente (típicamente para agregar series o finalizar el entrenamiento).
  /// Retorna la entidad Workout actualizada.
  /// Lanza una excepción si la operación falla o el entrenamiento no existe.
  Future<Workout> updateWorkout(Workout workout);

  /// Guarda un entrenamiento completado con todas sus series.
  /// Retorna true si el guardado fue exitoso, false en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<bool> saveWorkout(Workout workout);

  /// Obtiene el entrenamiento activo actual para un usuario (si existe).
  /// Retorna la entidad Workout activa si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Workout?> getActiveWorkout(int userId);

  /// Finaliza un entrenamiento activo estableciendo la hora de finalización.
  /// Retorna la entidad Workout completada.
  /// Lanza una excepción si la operación falla o el entrenamiento no existe.
  Future<Workout> endWorkout(int workoutId);
}

import '../entities/routine.dart';

/// Interfaz de repositorio para operaciones de datos de rutinas.
/// Define el contrato para el acceso a datos de rutinas sin detalles de implementación.
/// Esta interfaz será implementada en la capa de datos.
abstract class RoutineRepository {
  /// Obtiene todas las rutinas para un usuario específico.
  /// Retorna una lista de entidades Routine pertenecientes al usuario.
  /// Lanza una excepción si la operación falla.
  Future<List<Routine>> getUserRoutines(int userId);

  /// Obtiene una rutina específica por su ID.
  /// Retorna la entidad Routine si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Routine?> getRoutineById(int id);

  /// Crea una nueva rutina.
  /// Retorna la entidad Routine creada con ID asignado.
  /// Lanza una excepción si la operación falla.
  Future<Routine> createRoutine(Routine routine);

  /// Actualiza una rutina existente.
  /// Retorna la entidad Routine actualizada.
  /// Lanza una excepción si la operación falla o la rutina no existe.
  Future<Routine> updateRoutine(Routine routine);

  /// Elimina una rutina por su ID.
  /// Retorna true si la eliminación fue exitosa, false en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<bool> deleteRoutine(int id);
}

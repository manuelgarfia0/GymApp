import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

/// Caso de uso para obtener rutinas de usuario.
/// Encapsula la lógica de negocio para obtener rutinas.
class GetRoutines {
  final RoutineRepository _repository;

  GetRoutines(this._repository);

  /// Obtiene todas las rutinas para el usuario especificado.
  ///
  /// [userId] El ID del usuario cuyas rutinas obtener.
  ///
  /// Retorna una lista de entidades Routine pertenecientes al usuario.
  /// Retorna una lista vacía si no se encuentran rutinas.
  /// Lanza una excepción si la operación falla.
  Future<List<Routine>> call(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }

    return await _repository.getUserRoutines(userId);
  }

  /// Obtiene una rutina específica por su ID.
  ///
  /// [routineId] El ID de la rutina a obtener.
  ///
  /// Retorna la entidad Routine si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Routine?> getById(int routineId) async {
    if (routineId <= 0) {
      throw ArgumentError('Valid routine ID is required');
    }

    return await _repository.getRoutineById(routineId);
  }
}

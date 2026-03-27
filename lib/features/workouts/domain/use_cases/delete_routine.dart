import '../repositories/routine_repository.dart';

/// Caso de uso para eliminar una rutina existente.
class DeleteRoutine {
  final RoutineRepository _repository;

  DeleteRoutine(this._repository);

  Future<bool> call(int routineId) async {
    if (routineId <= 0) {
      throw ArgumentError('Valid routine ID is required');
    }
    return await _repository.deleteRoutine(routineId);
  }
}
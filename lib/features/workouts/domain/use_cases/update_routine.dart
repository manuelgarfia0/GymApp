import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

/// Caso de uso para actualizar una rutina existente.
class UpdateRoutine {
  final RoutineRepository _repository;

  UpdateRoutine(this._repository);

  Future<Routine> call(Routine routine) async {
    if (routine.id == null || routine.id! <= 0) {
      throw ArgumentError('Valid routine ID is required for update');
    }
    if (routine.name.trim().isEmpty) {
      throw ArgumentError('Routine name cannot be empty');
    }
    if (routine.exercises.isEmpty) {
      throw ArgumentError('Routine must contain at least one exercise');
    }
    return await _repository.updateRoutine(routine);
  }
}
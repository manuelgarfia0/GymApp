import '../repositories/workout_repository.dart';

/// Caso de uso para eliminar un entrenamiento por su identificador.
class DeleteWorkout {
  final WorkoutRepository _repository;

  const DeleteWorkout(this._repository);

  Future<bool> call(int id) async {
    if (id <= 0) {
      throw Exception('Valid workout ID is required');
    }
    return await _repository.deleteWorkout(id);
  }
}

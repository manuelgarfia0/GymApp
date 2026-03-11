import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

/// Use case for creating a new workout routine.
/// Encapsulates the business logic for routine creation.
class CreateRoutine {
  final RoutineRepository _repository;

  CreateRoutine(this._repository);

  /// Creates a new routine with the provided details.
  ///
  /// [routine] The routine entity to create (without ID).
  ///
  /// Returns the created Routine entity with assigned ID.
  /// Throws an exception if the creation fails or validation errors occur.
  Future<Routine> call(Routine routine) async {
    // Validate routine data
    _validateRoutine(routine);

    // Create the routine through the repository
    return await _repository.createRoutine(routine);
  }

  void _validateRoutine(Routine routine) {
    if (routine.name.trim().isEmpty) {
      throw ArgumentError('Routine name cannot be empty');
    }

    if (routine.userId <= 0) {
      throw ArgumentError('Valid user ID is required');
    }

    if (routine.exercises.isEmpty) {
      throw ArgumentError('Routine must contain at least one exercise');
    }

    // Validate each exercise in the routine
    for (final exercise in routine.exercises) {
      if (exercise.exerciseId <= 0) {
        throw ArgumentError('Valid exercise ID is required');
      }
      if (exercise.sets <= 0) {
        throw ArgumentError('Sets must be greater than 0');
      }
      if (exercise.reps <= 0) {
        throw ArgumentError('Reps must be greater than 0');
      }
      if (exercise.restSeconds < 0) {
        throw ArgumentError('Rest seconds cannot be negative');
      }
    }
  }
}

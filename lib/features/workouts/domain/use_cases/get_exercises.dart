import '../entities/exercise.dart';
import '../repositories/exercise_repository.dart';

/// Use case for retrieving exercises.
/// Encapsulates the business logic for fetching exercise data.
class GetExercises {
  final ExerciseRepository _repository;

  GetExercises(this._repository);

  /// Retrieves all available exercises.
  ///
  /// Returns a list of Exercise entities.
  /// Returns an empty list if no exercises are found.
  /// Throws an exception if the operation fails.
  Future<List<Exercise>> call() async {
    return await _repository.getExercises();
  }

  /// Retrieves a specific exercise by its ID.
  ///
  /// [exerciseId] The ID of the exercise to retrieve.
  ///
  /// Returns the Exercise entity if found, null otherwise.
  /// Throws an exception if the operation fails.
  Future<Exercise?> getById(int exerciseId) async {
    if (exerciseId <= 0) {
      throw ArgumentError('Valid exercise ID is required');
    }

    return await _repository.getExerciseById(exerciseId);
  }

  /// Searches for exercises by name or muscle group.
  ///
  /// [query] The search query (exercise name or muscle group).
  ///
  /// Returns a list of matching Exercise entities.
  /// Returns an empty list if no matches are found.
  /// Throws an exception if the operation fails.
  Future<List<Exercise>> search(String query) async {
    if (query.trim().isEmpty) {
      return await call(); // Return all exercises if query is empty
    }

    return await _repository.searchExercises(query.trim());
  }

  /// Filters exercises by primary muscle group.
  ///
  /// [exercises] The list of exercises to filter.
  /// [muscleGroup] The muscle group to filter by.
  ///
  /// Returns a filtered list of Exercise entities.
  List<Exercise> filterByMuscleGroup(
    List<Exercise> exercises,
    String muscleGroup,
  ) {
    if (muscleGroup.trim().isEmpty) {
      return exercises;
    }

    return exercises
        .where(
          (exercise) =>
              exercise.primaryMuscle.toLowerCase().contains(
                muscleGroup.toLowerCase(),
              ) ||
              exercise.secondaryMuscles.any(
                (muscle) =>
                    muscle.toLowerCase().contains(muscleGroup.toLowerCase()),
              ),
        )
        .toList();
  }

  /// Filters exercises by equipment type.
  ///
  /// [exercises] The list of exercises to filter.
  /// [equipment] The equipment type to filter by.
  ///
  /// Returns a filtered list of Exercise entities.
  List<Exercise> filterByEquipment(List<Exercise> exercises, String equipment) {
    if (equipment.trim().isEmpty) {
      return exercises;
    }

    return exercises
        .where(
          (exercise) => exercise.equipment.toLowerCase().contains(
            equipment.toLowerCase(),
          ),
        )
        .toList();
  }
}

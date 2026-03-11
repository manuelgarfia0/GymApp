import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/domain/entities/exercise.dart';

void main() {
  group('Exercise Entity', () {
    test('should create exercise with all properties', () {
      // Arrange & Act
      const exercise = Exercise(
        id: 1,
        name: 'Push-up',
        description: 'A basic bodyweight exercise',
        primaryMuscle: 'Chest',
        equipment: 'Bodyweight',
        secondaryMuscles: ['Triceps', 'Shoulders'],
      );

      // Assert
      expect(exercise.id, 1);
      expect(exercise.name, 'Push-up');
      expect(exercise.description, 'A basic bodyweight exercise');
      expect(exercise.primaryMuscle, 'Chest');
      expect(exercise.equipment, 'Bodyweight');
      expect(exercise.secondaryMuscles, ['Triceps', 'Shoulders']);
    });

    test('should support equality comparison', () {
      // Arrange
      const exercise1 = Exercise(
        id: 1,
        name: 'Push-up',
        description: 'A basic bodyweight exercise',
        primaryMuscle: 'Chest',
        equipment: 'Bodyweight',
        secondaryMuscles: ['Triceps'],
      );

      const exercise2 = Exercise(
        id: 1,
        name: 'Push-up',
        description: 'A basic bodyweight exercise',
        primaryMuscle: 'Chest',
        equipment: 'Bodyweight',
        secondaryMuscles: ['Triceps'],
      );

      // Act & Assert
      expect(exercise1, equals(exercise2));
      expect(exercise1.hashCode, equals(exercise2.hashCode));
    });

    test('should have proper toString representation', () {
      // Arrange
      const exercise = Exercise(
        id: 1,
        name: 'Push-up',
        description: 'A basic bodyweight exercise',
        primaryMuscle: 'Chest',
        equipment: 'Bodyweight',
        secondaryMuscles: [],
      );

      // Act
      final result = exercise.toString();

      // Assert
      expect(result, contains('Exercise'));
      expect(result, contains('id: 1'));
      expect(result, contains('name: Push-up'));
      expect(result, contains('primaryMuscle: Chest'));
      expect(result, contains('equipment: Bodyweight'));
    });
  });
}

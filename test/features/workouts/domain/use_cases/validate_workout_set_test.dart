import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/domain/entities/exercise.dart';
import 'package:gym_app/features/workouts/domain/use_cases/validate_workout_set.dart';

void main() {
  const barbellExercise = Exercise(
    id: 1,
    name: 'Bench Press',
    category: 'Barbell',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Triceps'],
  );

  const bodyweightExercise = Exercise(
    id: 2,
    name: 'Pull Up',
    category: 'Bodyweight',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps'],
  );

  group('WorkoutSetValidator', () {
    test('rejects null, negative, or 0 weight on weighted exercises', () {
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: null,
          reps: 10,
          exercise: barbellExercise,
        ),
        'Introduce el peso antes de completar la serie',
      );
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: -5,
          reps: 10,
          exercise: barbellExercise,
        ),
        'El peso no puede ser negativo',
      );
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: 0,
          reps: 10,
          exercise: barbellExercise,
        ),
        'El peso debe ser mayor que 0 kg para completar la serie',
      );
    });

    test('rejects missing or zero reps even when weight is valid', () {
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: 80,
          reps: null,
          exercise: barbellExercise,
        ),
        'Introduce las repeticiones antes de completar la serie',
      );
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: 80,
          reps: 0,
          exercise: barbellExercise,
        ),
        'Introduce las repeticiones antes de completar la serie',
      );
    });

    test('allows weight 0 on bodyweight exercises but still rejects null or negative', () {
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: null,
          reps: 12,
          exercise: bodyweightExercise,
        ),
        'Introduce el peso (0 si es sin lastre) antes de completar la serie',
      );
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: -1,
          reps: 12,
          exercise: bodyweightExercise,
        ),
        'El peso no puede ser negativo',
      );
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: 0,
          reps: 12,
          exercise: bodyweightExercise,
        ),
        isNull,
      );
    });

    test('accepts valid weighted sets with positive weight and reps', () {
      expect(
        WorkoutSetValidator.validateForCompletion(
          weight: 82.5,
          reps: 8,
          exercise: barbellExercise,
        ),
        isNull,
      );
    });
  });
}

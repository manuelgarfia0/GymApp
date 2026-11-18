import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/domain/entities/exercise.dart';
import 'package:gym_app/features/workouts/domain/entities/muscle_heatmap.dart';
import 'package:gym_app/features/workouts/domain/entities/workout.dart';
import 'package:gym_app/features/workouts/domain/use_cases/calculate_muscle_heatmap.dart';

void main() {
  const useCase = CalculateMuscleHeatmap();

  const benchPress = Exercise(
    id: 1,
    name: 'Bench Press',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Triceps', 'Shoulders'],
  );

  const barbellRow = Exercise(
    id: 2,
    name: 'Barbell Row',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Traps'],
  );

  const squat = Exercise(
    id: 3,
    name: 'Back Squat',
    primaryMuscle: 'Quadriceps',
    secondaryMuscles: ['Glutes', 'Hamstrings'],
  );

  final exercisesById = {
    1: benchPress,
    2: barbellRow,
    3: squat,
  };

  group('CalculateMuscleHeatmap', () {
    test('MuscleGroupKey.fromRawName resolves English, aliases and Spanish names', () {
      expect(MuscleGroupKey.fromRawName('Chest'), MuscleGroupKey.chest);
      expect(MuscleGroupKey.fromRawName('  pecho '), MuscleGroupKey.chest);
      expect(MuscleGroupKey.fromRawName('Back'), MuscleGroupKey.back);
      expect(MuscleGroupKey.fromRawName('dorsales'), MuscleGroupKey.back);
      expect(MuscleGroupKey.fromRawName('Quadriceps'), MuscleGroupKey.quadriceps);
      expect(MuscleGroupKey.fromRawName('Hamstrings'), MuscleGroupKey.hamstrings);
      expect(MuscleGroupKey.fromRawName('isquiotibiales'), MuscleGroupKey.hamstrings);
      expect(MuscleGroupKey.fromRawName('abs'), MuscleGroupKey.core);
      expect(MuscleGroupKey.fromRawName('unknown muscle'), isNull);
      expect(MuscleGroupKey.fromRawName('  '), isNull);
      expect(MuscleGroupKey.fromRawName(null), isNull);
    });

    test('weights primary sets 1.0 vs secondary 0.5, excludes warmups, and builds breakdown', () {
      final workout = Workout(
        id: 10,
        name: 'Upper Body',
        startTime: DateTime(2026, 11, 18, 18, 0),
        endTime: DateTime(2026, 11, 18, 19, 0),
        userId: 1,
        sets: [
          // Warmup should be excluded
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            exerciseOrder: 1,
            setNumber: 1,
            weight: 40,
            reps: 10,
            timestamp: DateTime(2026, 11, 18, 18, 5),
            isWarmup: true,
            isCompleted: true,
          ),
          // 2 working sets of Bench Press
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            exerciseOrder: 1,
            setNumber: 2,
            weight: 80,
            reps: 8,
            timestamp: DateTime(2026, 11, 18, 18, 10),
            isCompleted: true,
          ),
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            exerciseOrder: 1,
            setNumber: 3,
            weight: 80,
            reps: 8,
            timestamp: DateTime(2026, 11, 18, 18, 15),
            isCompleted: true,
          ),
        ],
      );

      final result = useCase(
        workouts: [workout],
        exercisesById: exercisesById,
      );

      expect(result.workoutCount, 1);
      expect(result.topMuscle, MuscleGroupKey.chest);

      final chest = result.activityFor(MuscleGroupKey.chest);
      expect(chest.primarySets, 2);
      expect(chest.secondarySets, 0);
      expect(chest.effectiveSets, 2.0);
      expect(chest.totalVolume, 1280.0); // 2 * 80 * 8
      expect(chest.intensityLevel, 4);
      expect(chest.exercises.single.exerciseName, 'Bench Press');
      expect(chest.exercises.single.isPrimary, isTrue);

      final triceps = result.activityFor(MuscleGroupKey.triceps);
      expect(triceps.primarySets, 0);
      expect(triceps.secondarySets, 2);
      expect(triceps.effectiveSets, 1.0); // 2 * 0.5
      expect(triceps.totalVolume, 640.0); // 50% of 1280
      expect(triceps.intensityLevel, 2); // 1.0 / 2.0 = 0.50 -> bucket 2
      expect(triceps.exercises.single.isPrimary, isFalse);

      final calves = result.activityFor(MuscleGroupKey.calves);
      expect(calves.effectiveSets, 0);
      expect(calves.intensityLevel, 0);
    });

    test('filters workouts cleanly across temporal ranges', () {
      final reference = DateTime(2026, 11, 18, 12, 0);
      final wOld = Workout(
        id: 1,
        name: 'Old Push',
        startTime: DateTime(2026, 9, 1, 10, 0),
        endTime: DateTime(2026, 9, 1, 11, 0),
        userId: 1,
        sets: [
          WorkoutSet(
            exerciseId: 1,
            exerciseOrder: 1,
            setNumber: 1,
            weight: 60,
            reps: 10,
            timestamp: DateTime(2026, 9, 1, 10, 5),
            isCompleted: true,
          ),
        ],
      );
      final w20DaysAgo = Workout(
        id: 2,
        name: 'Pull',
        startTime: DateTime(2026, 10, 29, 10, 0),
        endTime: DateTime(2026, 10, 29, 11, 0),
        userId: 1,
        sets: [
          WorkoutSet(
            exerciseId: 2,
            exerciseOrder: 1,
            setNumber: 1,
            weight: 70,
            reps: 10,
            timestamp: DateTime(2026, 10, 29, 10, 5),
            isCompleted: true,
          ),
        ],
      );
      final w2DaysAgo = Workout(
        id: 3,
        name: 'Legs',
        startTime: DateTime(2026, 11, 16, 10, 0),
        endTime: DateTime(2026, 11, 16, 11, 0),
        userId: 1,
        sets: [
          WorkoutSet(
            exerciseId: 3,
            exerciseOrder: 1,
            setNumber: 1,
            weight: 100,
            reps: 5,
            timestamp: DateTime(2026, 11, 16, 10, 5),
            isCompleted: true,
          ),
        ],
      );

      final allWorkouts = [w20DaysAgo, wOld, w2DaysAgo]; // out of order input

      final last = useCase(
        workouts: allWorkouts,
        exercisesById: exercisesById,
        range: MuscleHeatmapRange.lastWorkout,
        referenceDate: reference,
      );
      expect(last.workoutCount, 1);
      expect(last.topMuscle, MuscleGroupKey.quadriceps);
      expect(last.activityFor(MuscleGroupKey.chest).effectiveSets, 0);

      final last7 = useCase(
        workouts: allWorkouts,
        exercisesById: exercisesById,
        range: MuscleHeatmapRange.last7Days,
        referenceDate: reference,
      );
      expect(last7.workoutCount, 1);
      expect(last7.activityFor(MuscleGroupKey.quadriceps).primarySets, 1);
      expect(last7.activityFor(MuscleGroupKey.back).primarySets, 0);

      final last30 = useCase(
        workouts: allWorkouts,
        exercisesById: exercisesById,
        range: MuscleHeatmapRange.last30Days,
        referenceDate: reference,
      );
      expect(last30.workoutCount, 2);
      expect(last30.activityFor(MuscleGroupKey.back).primarySets, 1);
      expect(last30.activityFor(MuscleGroupKey.chest).primarySets, 0);

      final allTime = useCase(
        workouts: allWorkouts,
        exercisesById: exercisesById,
        range: MuscleHeatmapRange.allTime,
        referenceDate: reference,
      );
      expect(allTime.workoutCount, 3);
      expect(allTime.activityFor(MuscleGroupKey.chest).primarySets, 1);
      expect(allTime.activityFor(MuscleGroupKey.back).primarySets, 1);
      expect(allTime.activityFor(MuscleGroupKey.quadriceps).primarySets, 1);
    });

    test('falls back to normalized exercise name lookup when id is missing', () {
      final workout = Workout(
        id: 99,
        name: 'Name fallback',
        startTime: DateTime(2026, 11, 18, 10, 0),
        endTime: DateTime(2026, 11, 18, 11, 0),
        userId: 1,
        sets: [
          WorkoutSet(
            exerciseId: 9999,
            exerciseName: '  bench press ',
            exerciseOrder: 1,
            setNumber: 1,
            weight: 60,
            reps: 10,
            timestamp: DateTime(2026, 11, 18, 10, 5),
            isCompleted: true,
          ),
        ],
      );

      final result = useCase(
        workouts: [workout],
        exercisesById: const {},
        exercisesByName: {'Bench Press': benchPress},
      );

      expect(result.activityFor(MuscleGroupKey.chest).primarySets, 1);
      expect(result.activityFor(MuscleGroupKey.chest).totalVolume, 600);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/domain/entities/personal_record.dart';
import 'package:gym_app/features/workouts/domain/entities/workout.dart';
import 'package:gym_app/features/workouts/domain/use_cases/evaluate_personal_records.dart';

void main() {
  const useCase = EvaluatePersonalRecords();

  WorkoutSet makeSet({
    required int exerciseId,
    String exerciseName = 'Bench Press',
    int setNumber = 1,
    required double weight,
    required int reps,
    bool isWarmup = false,
    bool isCompleted = true,
  }) {
    return WorkoutSet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseOrder: 1,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      timestamp: DateTime(2026, 11, 10, 10, 0),
      isWarmup: isWarmup,
      isCompleted: isCompleted,
    );
  }

  Workout makeWorkout({
    int id = 1,
    DateTime? startTime,
    DateTime? endTime,
    required List<WorkoutSet> sets,
  }) {
    final start = startTime ?? DateTime(2026, 11, 10, 10, 0);
    return Workout(
      id: id,
      name: 'Push Day',
      startTime: start,
      endTime: endTime,
      userId: 1,
      sets: sets,
    );
  }

  group('EvaluatePersonalRecords', () {
    test('calculates Epley 1RM accurately for single and multiple reps', () {
      expect(EvaluatePersonalRecords.calculateEstimated1Rm(100, 1), 100.0);
      expect(
        EvaluatePersonalRecords.calculateEstimated1Rm(100, 10),
        closeTo(133.333, 0.01),
      );
      expect(EvaluatePersonalRecords.calculateEstimated1Rm(0, 10), 0.0);
      expect(EvaluatePersonalRecords.calculateEstimated1Rm(80, 0), 0.0);
    });

    test('builds historical baseline excluding warmup sets and active workouts', () {
      final history = [
        makeWorkout(
          id: 1,
          endTime: DateTime(2026, 11, 1, 11, 0),
          sets: [
            makeSet(exerciseId: 10, weight: 120, reps: 5, isWarmup: true),
            makeSet(exerciseId: 10, weight: 80, reps: 8),
            makeSet(exerciseId: 10, setNumber: 2, weight: 80, reps: 10),
          ],
        ),
        makeWorkout(
          id: 2,
          endTime: null, // Active workout must not pollute historical baseline.
          sets: [
            makeSet(exerciseId: 10, weight: 200, reps: 1),
          ],
        ),
      ];

      final baseline = useCase.buildBaselineFromHistory(history);
      final benchBest = baseline[10]!;

      expect(benchBest.maxWeight, 80.0);
      expect(benchBest.maxRepsAtMaxWeight, 10);
      expect(
        benchBest.maxEstimated1Rm,
        closeTo(EvaluatePersonalRecords.calculateEstimated1Rm(80, 10), 0.001),
      );
    });

    test('detects maxWeight, repRecord, estimated1Rm and in-session progression', () {
      const historical = ExerciseHistoricalBest(
        exerciseId: 10,
        exerciseName: 'Bench Press',
        maxWeight: 80,
        maxRepsAtMaxWeight: 8,
        maxEstimated1Rm: 101.33,
      );

      final result = useCase.evaluateExerciseSets(
        exerciseId: 10,
        exerciseName: 'Bench Press',
        historicalBest: historical,
        sets: [
          // Same weight & reps -> no PR.
          (setIndex: 0, weight: 80.0, reps: 8, isCompleted: true, isWarmup: false),
          // Warmup above max -> excluded.
          (setIndex: 1, weight: 90.0, reps: 5, isCompleted: true, isWarmup: true),
          // More reps at same maxWeight -> repRecord + estimated1Rm.
          (setIndex: 2, weight: 80.0, reps: 10, isCompleted: true, isWarmup: false),
          // Higher absolute weight -> maxWeight + estimated1Rm.
          (setIndex: 3, weight: 95.0, reps: 6, isCompleted: true, isWarmup: false),
          // Lighter/lower after previous in-session PR -> no PR.
          (setIndex: 4, weight: 85.0, reps: 5, isCompleted: true, isWarmup: false),
        ],
      );

      expect(result.keys.toList(), [2, 3]);
      expect(
        result[2]!.types,
        containsAll([
          PersonalRecordType.repRecord,
          PersonalRecordType.estimated1Rm,
        ]),
      );
      expect(
        result[3]!.types,
        containsAll([
          PersonalRecordType.maxWeight,
          PersonalRecordType.estimated1Rm,
        ]),
      );
      expect(result[3]!.previousMaxWeight, 80.0);
    });

    test('marks first benchmark when an exercise has no prior history', () {
      final result = useCase.evaluateExerciseSets(
        exerciseId: 99,
        exerciseName: 'Lateral Raise',
        sets: [
          (setIndex: 0, weight: 12.0, reps: 12, isCompleted: true, isWarmup: false),
          (setIndex: 1, weight: 12.0, reps: 10, isCompleted: true, isWarmup: false),
        ],
      );

      expect(result.keys.toList(), [0]);
      expect(result[0]!.types, {PersonalRecordType.firstBenchmark});
      expect(result[0]!.badgeLabel, '🏆 Nuevo PR');
    });

    test('evaluateWorkout summarizes PRs across exercises in a session', () {
      final history = [
        makeWorkout(
          id: 1,
          endTime: DateTime(2026, 11, 1, 11, 0),
          sets: [
            makeSet(exerciseId: 1, exerciseName: 'Squat', weight: 100, reps: 5),
            makeSet(exerciseId: 2, exerciseName: 'OHP', weight: 50, reps: 8),
          ],
        ),
      ];
      final baseline = useCase.buildBaselineFromHistory(history);

      final current = makeWorkout(
        id: 2,
        startTime: DateTime(2026, 11, 17, 10, 0),
        endTime: DateTime(2026, 11, 17, 11, 0),
        sets: [
          makeSet(
            exerciseId: 1,
            exerciseName: 'Squat',
            setNumber: 1,
            weight: 105,
            reps: 5,
          ),
          makeSet(
            exerciseId: 2,
            exerciseName: 'OHP',
            setNumber: 1,
            weight: 50,
            reps: 6,
          ),
        ],
      );

      final prs = useCase.evaluateWorkout(current, baseline);
      expect(prs.length, 1);
      expect(prs.first.exerciseId, 1);
      expect(prs.first.weight, 105);
      expect(prs.first.types, contains(PersonalRecordType.maxWeight));
    });
  });
}

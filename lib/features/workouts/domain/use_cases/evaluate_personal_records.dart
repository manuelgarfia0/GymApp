import '../entities/personal_record.dart';
import '../entities/workout.dart';

/// Descriptor ligero de serie para evaluar récords personales sin acoplar el
/// dominio a modelos de estado de UI.
typedef EvaluableSetInput = ({
  int setIndex,
  double? weight,
  int? reps,
  bool isCompleted,
  bool isWarmup,
});

/// Caso de uso de dominio puro para calcular marcas históricas y detectar
/// sobrecarga progresiva y récords personales (PR) por serie y sesión.
class EvaluatePersonalRecords {
  const EvaluatePersonalRecords();

  /// Calcula el 1RM estimado usando la fórmula de Epley.
  static double calculateEstimated1Rm(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1.0 + reps / 30.0);
  }

  /// Construye el mejor registro histórico por `exerciseId` a partir de sesiones
  /// completadas, excluyendo calentamientos y opcionalmente un entrenamiento actual.
  Map<int, ExerciseHistoricalBest> buildBaselineFromHistory(
    List<Workout> workouts, {
    int? excludeWorkoutId,
    DateTime? beforeDate,
  }) {
    final baselines = <int, _RunningBest>{};

    for (final workout in workouts) {
      if (workout.isActive) continue;
      if (excludeWorkoutId != null && workout.id == excludeWorkoutId) continue;
      if (beforeDate != null && !workout.startTime.isBefore(beforeDate)) {
        continue;
      }

      for (final set in workout.sets) {
        if (set.isWarmup || set.weight <= 0 || set.reps <= 0) continue;

        final est1Rm = calculateEstimated1Rm(set.weight, set.reps);
        final current = baselines.putIfAbsent(
          set.exerciseId,
          () => _RunningBest(
            exerciseId: set.exerciseId,
            exerciseName: set.exerciseName ?? 'Exercise #${set.exerciseId}',
          ),
        );
        current.absorb(set.weight, set.reps, est1Rm);
      }
    }

    return baselines.map(
      (exerciseId, best) => MapEntry(exerciseId, best.toHistoricalBest()),
    );
  }

  /// Evalúa en orden las series de un ejercicio y devuelve un mapa con los
  /// récords personales alcanzados indexados por `setIndex`.
  Map<int, PersonalRecordAchievement> evaluateExerciseSets({
    required int exerciseId,
    required String exerciseName,
    required List<EvaluableSetInput> sets,
    ExerciseHistoricalBest? historicalBest,
  }) {
    final results = <int, PersonalRecordAchievement>{};
    final running = historicalBest != null
        ? _RunningBest.fromHistorical(historicalBest)
        : _RunningBest(exerciseId: exerciseId, exerciseName: exerciseName);

    for (final item in sets) {
      final weight = item.weight;
      final reps = item.reps;
      if (!item.isCompleted ||
          item.isWarmup ||
          weight == null ||
          reps == null ||
          weight <= 0 ||
          reps <= 0) {
        continue;
      }

      final est1Rm = calculateEstimated1Rm(weight, reps);
      final achievement = running.evaluateAndAdvance(
        setNumber: item.setIndex + 1,
        weight: weight,
        reps: reps,
        estimated1Rm: est1Rm,
      );
      if (achievement != null) {
        results[item.setIndex] = achievement;
      }
    }

    return results;
  }

  /// Evalúa un entrenamiento completo frente a la línea base histórica y
  /// devuelve todos los logros de PR ordenados cronológicamente por ejercicio y serie.
  List<PersonalRecordAchievement> evaluateWorkout(
    Workout workout,
    Map<int, ExerciseHistoricalBest> baseline,
  ) {
    final setsByExercise = <int, List<WorkoutSet>>{};
    final exerciseNames = <int, String>{};

    for (final set in workout.sets) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
      exerciseNames.putIfAbsent(
        set.exerciseId,
        () => set.exerciseName ?? 'Exercise #${set.exerciseId}',
      );
    }

    final achievements = <PersonalRecordAchievement>[];
    for (final entry in setsByExercise.entries) {
      final exId = entry.key;
      final orderedSets = [...entry.value]
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      final inputs = List<EvaluableSetInput>.generate(
        orderedSets.length,
        (index) {
          final s = orderedSets[index];
          return (
            setIndex: index,
            weight: s.weight,
            reps: s.reps,
            isCompleted: true,
            isWarmup: s.isWarmup,
          );
        },
      );

      final prMap = evaluateExerciseSets(
        exerciseId: exId,
        exerciseName: exerciseNames[exId]!,
        sets: inputs,
        historicalBest: baseline[exId],
      );

      for (final idx in prMap.keys.toList()..sort()) {
        final rawPr = prMap[idx]!;
        final actualSetNumber = orderedSets[idx].setNumber;
        achievements.add(
          PersonalRecordAchievement(
            exerciseId: rawPr.exerciseId,
            exerciseName: rawPr.exerciseName,
            setNumber: actualSetNumber,
            weight: rawPr.weight,
            reps: rawPr.reps,
            estimated1Rm: rawPr.estimated1Rm,
            previousMaxWeight: rawPr.previousMaxWeight,
            previousMax1Rm: rawPr.previousMax1Rm,
            types: rawPr.types,
          ),
        );
      }
    }

    return achievements;
  }

  /// Clave estable para indexar los récords calculados de un [Workout].
  static int workoutKey(Workout workout) =>
      workout.id ?? identityHashCode(workout);

  /// Evalúa cronológicamente una lista de entrenamientos completados y devuelve
  /// los récords personales batidos en cada sesión indexados por [workoutKey].
  Map<int, List<PersonalRecordAchievement>> evaluateHistoryByWorkout(
    List<Workout> workouts,
  ) {
    final completed = workouts.where((w) => !w.isActive).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final baseline = <int, _RunningBest>{};
    final result = <int, List<PersonalRecordAchievement>>{};

    for (final workout in completed) {
      final baselineSnapshot = baseline.map(
        (id, best) => MapEntry(id, best.toHistoricalBest()),
      );
      result[workoutKey(workout)] = evaluateWorkout(workout, baselineSnapshot);

      for (final set in workout.sets) {
        if (set.isWarmup || set.weight <= 0 || set.reps <= 0) continue;
        final est1Rm = calculateEstimated1Rm(set.weight, set.reps);
        final running = baseline.putIfAbsent(
          set.exerciseId,
          () => _RunningBest(
            exerciseId: set.exerciseId,
            exerciseName: set.exerciseName ?? 'Exercise #${set.exerciseId}',
          ),
        );
        running.absorb(set.weight, set.reps, est1Rm);
      }
    }

    return result;
  }
}

class _RunningBest {
  final int exerciseId;
  final String exerciseName;
  double maxWeight = 0.0;
  int maxRepsAtMaxWeight = 0;
  double maxEstimated1Rm = 0.0;
  bool hasHistory = false;

  _RunningBest({
    required this.exerciseId,
    required this.exerciseName,
  });

  factory _RunningBest.fromHistorical(ExerciseHistoricalBest best) {
    return _RunningBest(
      exerciseId: best.exerciseId,
      exerciseName: best.exerciseName,
    )
      ..maxWeight = best.maxWeight
      ..maxRepsAtMaxWeight = best.maxRepsAtMaxWeight
      ..maxEstimated1Rm = best.maxEstimated1Rm
      ..hasHistory = best.maxWeight > 0;
  }

  void absorb(double weight, int reps, double est1Rm) {
    hasHistory = true;
    if (weight > maxWeight + 1e-6) {
      maxWeight = weight;
      maxRepsAtMaxWeight = reps;
    } else if ((weight - maxWeight).abs() <= 1e-6 &&
        reps > maxRepsAtMaxWeight) {
      maxRepsAtMaxWeight = reps;
    }
    if (est1Rm > maxEstimated1Rm) {
      maxEstimated1Rm = est1Rm;
    }
  }

  PersonalRecordAchievement? evaluateAndAdvance({
    required int setNumber,
    required double weight,
    required int reps,
    required double estimated1Rm,
  }) {
    if (!hasHistory) {
      absorb(weight, reps, estimated1Rm);
      return PersonalRecordAchievement(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        setNumber: setNumber,
        weight: weight,
        reps: reps,
        estimated1Rm: estimated1Rm,
        types: const {PersonalRecordType.firstBenchmark},
      );
    }

    final types = <PersonalRecordType>{};
    final prevWeight = maxWeight;
    final prev1Rm = maxEstimated1Rm;

    if (weight > maxWeight + 1e-6) {
      types.add(PersonalRecordType.maxWeight);
    } else if ((weight - maxWeight).abs() <= 1e-6 &&
        reps > maxRepsAtMaxWeight) {
      types.add(PersonalRecordType.repRecord);
    }

    if (estimated1Rm > maxEstimated1Rm + 0.05) {
      types.add(PersonalRecordType.estimated1Rm);
    }

    if (types.isEmpty) {
      return null;
    }

    absorb(weight, reps, estimated1Rm);

    return PersonalRecordAchievement(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      estimated1Rm: estimated1Rm,
      previousMaxWeight: prevWeight,
      previousMax1Rm: prev1Rm,
      types: types,
    );
  }

  ExerciseHistoricalBest toHistoricalBest() => ExerciseHistoricalBest(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        maxWeight: maxWeight,
        maxRepsAtMaxWeight: maxRepsAtMaxWeight,
        maxEstimated1Rm: maxEstimated1Rm,
      );
}

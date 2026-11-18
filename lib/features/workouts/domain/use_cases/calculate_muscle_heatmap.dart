import '../entities/exercise.dart';
import '../entities/muscle_heatmap.dart';
import '../entities/workout.dart';

/// Calcula la activación muscular anatómica agregada a partir de entrenamientos
/// y el catálogo de ejercicios, distinguiendo músculo primario y secundarios.
class CalculateMuscleHeatmap {
  const CalculateMuscleHeatmap();

  static const double secondaryWeight = 0.5;

  /// Mapea una proporción normalizada `0..1` a un nivel de intensidad `0..4`.
  static int intensityLevelForRatio(double ratio) {
    if (ratio <= 0) return 0;
    if (ratio <= 0.25) return 1;
    if (ratio <= 0.50) return 2;
    if (ratio <= 0.75) return 3;
    return 4;
  }

  MuscleHeatmapData call({
    required List<Workout> workouts,
    required Map<int, Exercise> exercisesById,
    Map<String, Exercise>? exercisesByName,
    MuscleHeatmapRange range = MuscleHeatmapRange.allTime,
    DateTime? referenceDate,
    bool includeIncompleteSets = false,
  }) {
    final candidates = includeIncompleteSets
        ? List<Workout>.from(workouts)
        : workouts.where((w) => w.endTime != null).toList();
    if (candidates.isEmpty) return MuscleHeatmapData.empty;

    candidates.sort((a, b) => a.startTime.compareTo(b.startTime));

    final today = _normalizeDate(referenceDate ?? DateTime.now());
    final filtered = _filterByRange(candidates, range, today);
    if (filtered.isEmpty) return MuscleHeatmapData.empty;

    final normalizedByName = _buildNormalizedNameMap(
      exercisesById,
      exercisesByName,
    );

    final accumulators = <MuscleGroupKey, _MuscleAccumulator>{
      for (final key in MuscleGroupKey.values) key: _MuscleAccumulator(),
    };

    for (final workout in filtered) {
      for (final set in workout.sets) {
        if (set.isWarmup) continue;
        final hasEffort =
            (set.weight > 0 && set.reps > 0) || set.isCompleted;
        if (!includeIncompleteSets && !hasEffort) continue;

        final exercise = _resolveExercise(
          set,
          exercisesById,
          normalizedByName,
        );
        if (exercise == null) continue;

        final rawVolume =
            (set.weight > 0 && set.reps > 0) ? set.weight * set.reps : 0.0;
        final displayName = (set.exerciseName?.trim().isNotEmpty ?? false)
            ? set.exerciseName!.trim()
            : exercise.name;

        final primaryKey = MuscleGroupKey.fromRawName(exercise.primaryMuscle);
        if (primaryKey != null) {
          accumulators[primaryKey]!.addSet(
            weightFactor: 1.0,
            volume: rawVolume,
            exerciseName: displayName,
            isPrimary: true,
          );
        }

        final seenSecondary = <MuscleGroupKey>{};
        for (final rawSecondary in exercise.secondaryMuscles) {
          final secondaryKey = MuscleGroupKey.fromRawName(rawSecondary);
          if (secondaryKey == null ||
              secondaryKey == primaryKey ||
              !seenSecondary.add(secondaryKey)) {
            continue;
          }
          accumulators[secondaryKey]!.addSet(
            weightFactor: secondaryWeight,
            volume: rawVolume * secondaryWeight,
            exerciseName: displayName,
            isPrimary: false,
          );
        }
      }
    }

    double maxEffectiveSets = 0;
    double totalEffectiveSets = 0;
    MuscleGroupKey? topMuscle;
    double topEffectiveSets = 0;
    double topVolume = -1;

    for (final key in MuscleGroupKey.values) {
      final acc = accumulators[key]!;
      totalEffectiveSets += acc.effectiveSets;
      if (acc.effectiveSets > maxEffectiveSets) {
        maxEffectiveSets = acc.effectiveSets;
      }
      if (acc.effectiveSets > 0 &&
          (acc.effectiveSets > topEffectiveSets ||
              (acc.effectiveSets == topEffectiveSets &&
                  acc.totalVolume > topVolume))) {
        topMuscle = key;
        topEffectiveSets = acc.effectiveSets;
        topVolume = acc.totalVolume;
      }
    }

    final activities = <MuscleGroupKey, MuscleActivity>{};
    for (final key in MuscleGroupKey.values) {
      final acc = accumulators[key]!;
      final double intensity = maxEffectiveSets > 0 && acc.effectiveSets > 0
          ? (acc.effectiveSets / maxEffectiveSets).clamp(0.0, 1.0)
          : 0.0;
      final int level = acc.effectiveSets > 0
          ? intensityLevelForRatio(intensity)
          : 0;

      activities[key] = MuscleActivity(
        muscle: key,
        primarySets: acc.primarySets,
        secondarySets: acc.secondarySets,
        effectiveSets: acc.effectiveSets,
        totalVolume: acc.totalVolume,
        intensity: intensity,
        intensityLevel: level,
        exercises: acc.buildBreakdown(),
      );
    }

    return MuscleHeatmapData(
      activities: activities,
      workoutCount: filtered.length,
      totalEffectiveSets: totalEffectiveSets,
      topMuscle: topMuscle,
    );
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  List<Workout> _filterByRange(
    List<Workout> sortedWorkouts,
    MuscleHeatmapRange range,
    DateTime today,
  ) {
    switch (range) {
      case MuscleHeatmapRange.lastWorkout:
        return [sortedWorkouts.last];
      case MuscleHeatmapRange.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return sortedWorkouts
            .where((w) => !_normalizeDate(w.startTime).isBefore(start))
            .toList();
      case MuscleHeatmapRange.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return sortedWorkouts
            .where((w) => !_normalizeDate(w.startTime).isBefore(start))
            .toList();
      case MuscleHeatmapRange.allTime:
        return sortedWorkouts;
    }
  }

  Map<String, Exercise> _buildNormalizedNameMap(
    Map<int, Exercise> exercisesById,
    Map<String, Exercise>? exercisesByName,
  ) {
    if (exercisesByName != null) {
      return {
        for (final entry in exercisesByName.entries)
          entry.key.trim().toLowerCase(): entry.value,
      };
    }
    return {
      for (final ex in exercisesById.values) ex.name.trim().toLowerCase(): ex,
    };
  }

  Exercise? _resolveExercise(
    WorkoutSet set,
    Map<int, Exercise> exercisesById,
    Map<String, Exercise> exercisesByName,
  ) {
    final byId = exercisesById[set.exerciseId];
    if (byId != null) return byId;
    final name = set.exerciseName?.trim().toLowerCase();
    if (name == null || name.isEmpty) return null;
    return exercisesByName[name];
  }
}

class _MuscleAccumulator {
  int primarySets = 0;
  int secondarySets = 0;
  double effectiveSets = 0;
  double totalVolume = 0;
  final Map<String, _ExerciseBreakdownAccumulator> _exercises = {};

  void addSet({
    required double weightFactor,
    required double volume,
    required String exerciseName,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      primarySets++;
    } else {
      secondarySets++;
    }
    effectiveSets += weightFactor;
    totalVolume += volume;

    final key = '${exerciseName.toLowerCase()}|${isPrimary ? 1 : 0}';
    final entry = _exercises.putIfAbsent(
      key,
      () => _ExerciseBreakdownAccumulator(
        exerciseName: exerciseName,
        isPrimary: isPrimary,
      ),
    );
    entry.sets++;
    entry.volume += volume;
  }

  List<MuscleExerciseBreakdown> buildBreakdown() {
    final list = _exercises.values
        .map(
          (e) => MuscleExerciseBreakdown(
            exerciseName: e.exerciseName,
            sets: e.sets,
            volume: e.volume,
            isPrimary: e.isPrimary,
          ),
        )
        .toList();
    list.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      final setsCmp = b.sets.compareTo(a.sets);
      if (setsCmp != 0) return setsCmp;
      final volCmp = b.volume.compareTo(a.volume);
      if (volCmp != 0) return volCmp;
      return a.exerciseName.compareTo(b.exerciseName);
    });
    return list;
  }
}

class _ExerciseBreakdownAccumulator {
  final String exerciseName;
  final bool isPrimary;
  int sets = 0;
  double volume = 0;

  _ExerciseBreakdownAccumulator({
    required this.exerciseName,
    required this.isPrimary,
  });
}

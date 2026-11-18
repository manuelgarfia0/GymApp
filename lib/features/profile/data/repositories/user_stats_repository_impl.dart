import '../../domain/use_cases/get_user_stats.dart';
import '../../../workouts/domain/entities/exercise.dart';
import '../../../workouts/domain/entities/muscle_heatmap.dart';
import '../../../workouts/domain/repositories/exercise_repository.dart';
import '../../../workouts/domain/repositories/workout_repository.dart';
import '../../../workouts/domain/use_cases/calculate_muscle_heatmap.dart';
import '../../../workouts/domain/use_cases/evaluate_personal_records.dart';

/// Implementa [UserStatsRepository] consultando [WorkoutRepository].
class UserStatsRepositoryImpl implements UserStatsRepository {
  final WorkoutRepository _workoutRepository;
  final ExerciseRepository? _exerciseRepository;
  final EvaluatePersonalRecords _evaluatePersonalRecords;
  final CalculateMuscleHeatmap _calculateMuscleHeatmap;

  const UserStatsRepositoryImpl(
    this._workoutRepository, {
    ExerciseRepository? exerciseRepository,
    EvaluatePersonalRecords evaluatePersonalRecords =
        const EvaluatePersonalRecords(),
    CalculateMuscleHeatmap calculateMuscleHeatmap =
        const CalculateMuscleHeatmap(),
  }) : _exerciseRepository = exerciseRepository,
       _evaluatePersonalRecords = evaluatePersonalRecords,
       _calculateMuscleHeatmap = calculateMuscleHeatmap;

  @override
  Future<UserStats> getStats(int userId) async {
    final workoutsFuture = _workoutRepository.getUserWorkouts(userId);
    final exercisesFuture = _loadExercisesSafely();
    final workouts = await workoutsFuture;
    final exercises = await exercisesFuture;

    final completed = workouts.where((w) => w.endTime != null).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final total = completed.fold<Duration>(
      Duration.zero,
      (sum, w) => sum + w.endTime!.difference(w.startTime),
    );
    final h = total.inHours.toString().padLeft(2, '0');
    final m = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    final timeLabel = '$h:$m:$s';

    final prsByWorkout =
        _evaluatePersonalRecords.evaluateHistoryByWorkout(completed);

    double totalVolume = 0;
    final volumeHistory = <DateTime, double>{};
    final exerciseCounts = <String, int>{};
    final dates = <DateTime>[];
    final workoutsByDate = <DateTime, List<ProfileWorkoutSummary>>{};

    for (final w in completed) {
      double workoutVolume = 0;
      final uniqueExercises = <String>{};

      dates.add(w.startTime);
      for (final set in w.sets) {
        if (!set.isWarmup && ((set.weight > 0 && set.reps > 0) || set.isCompleted)) {
          workoutVolume += set.weight * set.reps;
          final exName = set.exerciseName ?? 'Unknown';
          exerciseCounts[exName] = (exerciseCounts[exName] ?? 0) + 1;
          uniqueExercises.add(exName);
        }
      }
      totalVolume += workoutVolume;

      final day = DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      volumeHistory[day] = (volumeHistory[day] ?? 0) + workoutVolume;

      final dur =
          w.endTime != null ? w.endTime!.difference(w.startTime) : Duration.zero;
      final prs =
          prsByWorkout[EvaluatePersonalRecords.workoutKey(w)] ?? const [];

      workoutsByDate.putIfAbsent(day, () => []).add(
            ProfileWorkoutSummary(
              id: w.id ?? 0,
              name: w.name,
              startTime: w.startTime,
              duration: dur,
              volume: workoutVolume,
              exercises: uniqueExercises.toList(),
              setCount: w.sets.length,
              workout: w,
              personalRecords: prs,
            ),
          );
    }

    final mostFrequent = _findMostFrequentExercise(exerciseCounts);
    final distinctDays = workoutsByDate.keys.toList()..sort();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneYearAgo = today.subtract(const Duration(days: 364));

    final activeDaysLastYear =
        distinctDays.where((d) => !d.isBefore(oneYearAgo)).length;

    final exercisesById = <int, Exercise>{
      for (final ex in exercises) ex.id: ex,
    };
    final exercisesByName = <String, Exercise>{
      for (final ex in exercises) ex.name.trim().toLowerCase(): ex,
    };
    final muscleHeatmaps = <MuscleHeatmapRange, MuscleHeatmapData>{
      for (final range in MuscleHeatmapRange.values)
        range: _calculateMuscleHeatmap(
          workouts: completed,
          exercisesById: exercisesById,
          exercisesByName: exercisesByName,
          range: range,
          referenceDate: now,
        ),
    };

    return UserStats(
      totalWorkouts: completed.length,
      totalTime: timeLabel,
      totalVolume: totalVolume,
      currentStreak: _calculateCurrentStreak(distinctDays, today),
      longestStreak: _calculateLongestStreak(distinctDays),
      activeDaysLastYear: activeDaysLastYear,
      mostFrequentExercise: mostFrequent,
      workoutDates: dates,
      volumeHistory: volumeHistory,
      workoutsByDate: workoutsByDate,
      muscleHeatmaps: muscleHeatmaps,
    );
  }

  Future<List<Exercise>> _loadExercisesSafely() async {
    final repo = _exerciseRepository;
    if (repo == null) return const [];
    try {
      return await repo.getExercises();
    } catch (_) {
      return const [];
    }
  }

  String _findMostFrequentExercise(Map<String, int> counts) {
    String mostFrequent = 'None';
    int maxCount = 0;
    counts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        mostFrequent = key;
      }
    });
    return mostFrequent;
  }

  int _calculateCurrentStreak(List<DateTime> sortedDays, DateTime today) {
    if (sortedDays.isEmpty) return 0;
    final lastDay = sortedDays.last;
    if (today.difference(lastDay).inDays > 1) return 0;

    int streak = 1;
    for (int i = sortedDays.length - 2; i >= 0; i--) {
      if (sortedDays[i + 1].difference(sortedDays[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<DateTime> sortedDays) {
    if (sortedDays.isEmpty) return 0;
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i].difference(sortedDays[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}

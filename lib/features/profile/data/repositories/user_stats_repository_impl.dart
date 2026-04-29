import '../../domain/use_cases/get_user_stats.dart';
import '../../../workouts/domain/repositories/workout_repository.dart';

/// Implementa [UserStatsRepository] consultando [WorkoutRepository].
class UserStatsRepositoryImpl implements UserStatsRepository {
  final WorkoutRepository _workoutRepository;

  const UserStatsRepositoryImpl(this._workoutRepository);

  @override
  Future<UserStats> getStats(int userId) async {
    final workouts = await _workoutRepository.getUserWorkouts(userId);
    final completed = workouts.where((w) => w.endTime != null).toList();
    
    // Total Time
    final total = completed.fold<Duration>(
      Duration.zero,
      (sum, w) => sum + w.endTime!.difference(w.startTime),
    );
    final h = total.inHours;
    final m = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    final timeLabel = '${h.toString().padLeft(2, '0')}:$m:$s';

    // Total Volume & Volume History & Frequent Exercise
    double totalVolume = 0;
    final Map<DateTime, double> volumeHistory = {};
    final Map<String, int> exerciseCounts = {};
    final List<DateTime> dates = [];
    final Map<DateTime, List<ProfileWorkoutSummary>> workoutsByDate = {};

    // Sort by start time oldest first
    completed.sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final w in completed) {
      double workoutVolume = 0;
      final Set<String> uniqueExercises = {};
      
      dates.add(w.startTime);
      for (final set in w.sets) {
        if (!set.isWarmup && set.isCompleted) {
          workoutVolume += set.weight * set.reps;
          final exName = set.exerciseName ?? 'Unknown';
          exerciseCounts[exName] = (exerciseCounts[exName] ?? 0) + 1;
          uniqueExercises.add(exName);
        }
      }
      totalVolume += workoutVolume;
      // Truncate to Day precision for history chart
      final day = DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      volumeHistory[day] = (volumeHistory[day] ?? 0) + workoutVolume;
      
      final dur = w.endTime != null ? w.endTime!.difference(w.startTime) : Duration.zero;
      final summary = ProfileWorkoutSummary(
        id: w.id ?? 0,
        name: w.name,
        startTime: w.startTime,
        duration: dur,
        volume: workoutVolume,
        exercises: uniqueExercises.toList(),
      );
      
      workoutsByDate.putIfAbsent(day, () => []).add(summary);
    }

    String mostFrequent = 'None';
    int maxCount = 0;
    exerciseCounts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        mostFrequent = key;
      }
    });

    // Current Streak (simple logic)
    int streak = 0;
    if (completed.isNotEmpty) {
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime lastWorkoutDay = DateTime(completed.last.startTime.year, completed.last.startTime.month, completed.last.startTime.day);
      
      if (today.difference(lastWorkoutDay).inDays <= 1) {
        streak = 1;
        for (int i = completed.length - 2; i >= 0; i--) {
          final wDay = DateTime(completed[i].startTime.year, completed[i].startTime.month, completed[i].startTime.day);
          if (lastWorkoutDay.difference(wDay).inDays == 1) {
            streak++;
            lastWorkoutDay = wDay;
          } else if (lastWorkoutDay.difference(wDay).inDays == 0) {
            continue; // same day
          } else {
            break;
          }
        }
      }
    }

    return UserStats(
      totalWorkouts: completed.length,
      totalTime: timeLabel,
      totalVolume: totalVolume,
      currentStreak: streak,
      mostFrequentExercise: mostFrequent,
      workoutDates: dates,
      volumeHistory: volumeHistory,
      workoutsByDate: workoutsByDate,
    );
  }
}

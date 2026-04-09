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

    final total = completed.fold<Duration>(
      Duration.zero,
      (sum, w) => sum + w.endTime!.difference(w.startTime),
    );
    final h = total.inHours;
    final m = total.inMinutes.remainder(60);
    final timeLabel = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}'
        : '${total.inMinutes} min';

    return UserStats(totalWorkouts: completed.length, totalTime: timeLabel);
  }
}

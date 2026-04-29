class ProfileWorkoutSummary {
  final int id;
  final String name;
  final DateTime startTime;
  final Duration duration;
  final double volume;
  final List<String> exercises;

  const ProfileWorkoutSummary({
    required this.id,
    required this.name,
    required this.startTime,
    required this.duration,
    required this.volume,
    required this.exercises,
  });
}

/// Estadísticas de entrenamiento del usuario para mostrar en el perfil.
/// Se define en el feature de profile para que [ProfileScreen] no tenga
/// que importar [WorkoutDependencies] directamente, lo que violaría el
/// límite entre features en la clean architecture.
class UserStats {
  final int totalWorkouts;
  final String totalTime;
  final double totalVolume;
  final int currentStreak;
  final String mostFrequentExercise;
  final List<DateTime> workoutDates;
  final Map<DateTime, double> volumeHistory;
  final Map<DateTime, List<ProfileWorkoutSummary>> workoutsByDate;

  const UserStats({
    required this.totalWorkouts,
    required this.totalTime,
    required this.totalVolume,
    required this.currentStreak,
    required this.mostFrequentExercise,
    required this.workoutDates,
    required this.volumeHistory,
    required this.workoutsByDate,
  });

  static const empty = UserStats(
    totalWorkouts: 0,
    totalTime: '00:00:00',
    totalVolume: 0.0,
    currentStreak: 0,
    mostFrequentExercise: 'None',
    workoutDates: [],
    volumeHistory: {},
    workoutsByDate: {},
  );
}

/// Puerto (interfaz) que el feature de profile requiere para obtener
/// estadísticas de entrenamientos. La implementación real vive en
/// [ProfileDependencies] y delega a [WorkoutRepository].
abstract class UserStatsRepository {
  Future<UserStats> getStats(int userId);
}

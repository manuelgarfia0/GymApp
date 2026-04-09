/// Estadísticas de entrenamiento del usuario para mostrar en el perfil.
/// Se define en el feature de profile para que [ProfileScreen] no tenga
/// que importar [WorkoutDependencies] directamente, lo que violaría el
/// límite entre features en la clean architecture.
class UserStats {
  final int totalWorkouts;
  final String totalTime;

  const UserStats({required this.totalWorkouts, required this.totalTime});

  static const empty = UserStats(totalWorkouts: 0, totalTime: '0m');
}

/// Puerto (interfaz) que el feature de profile requiere para obtener
/// estadísticas de entrenamientos. La implementación real vive en
/// [ProfileDependencies] y delega a [WorkoutRepository].
abstract class UserStatsRepository {
  Future<UserStats> getStats(int userId);
}

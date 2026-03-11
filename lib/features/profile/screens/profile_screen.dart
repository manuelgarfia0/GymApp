import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/failures.dart';
import '../../workouts/domain/entities/workout.dart';
import '../../workouts/domain/use_cases/get_workout_history.dart';
import '../../workouts/workout_dependencies.dart';
import '../domain/entities/user_profile.dart';
import '../domain/use_cases/get_current_user_profile.dart';
import '../profile_dependencies.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Use cases para operaciones de perfil y workouts
  late final GetCurrentUserProfile _getCurrentUserProfile;
  late final GetWorkoutHistory _getWorkoutHistory;

  UserProfile? _user;
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUseCases();
    _loadDashboardData();
  }

  void _initializeUseCases() {
    // Inicializar los use cases con sus dependencias
    _getCurrentUserProfile = ProfileDependencies.getCurrentUserProfileUseCase;
    _getWorkoutHistory = WorkoutDependencies.getWorkoutHistoryUseCase;
  }

  // Carga asíncrona de todos los datos necesarios para el dashboard
  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('user_id') ?? 0;

    if (userId == 0) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Usar los use cases del dominio para obtener datos
      final user = await _getCurrentUserProfile();
      final workouts = await _getWorkoutHistory(userId);

      if (mounted) {
        setState(() {
          _user = user;
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } on AuthenticationFailure catch (e) {
      if (mounted) {
        setState(() {
          _user = null;
          _workouts = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on NetworkFailure catch (e) {
      if (mounted) {
        setState(() {
          _user = null;
          _workouts = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadDashboardData();
              },
            ),
          ),
        );
      }
    } on ValidationFailure catch (e) {
      if (mounted) {
        setState(() {
          _user = null;
          _workouts = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = null;
          _workouts = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadDashboardData();
              },
            ),
          ),
        );
      }
    }
  }

  // Calcula el tiempo total de entrenamiento sumando la duración de cada sesión
  String _calculateTotalTime() {
    Duration totalDuration = Duration.zero;

    for (var workout in _workouts) {
      if (workout.endTime != null) {
        try {
          Duration workoutDuration = workout.endTime!.difference(
            workout.startTime,
          );
          totalDuration += workoutDuration;
        } catch (e) {
          // Ignoramos errores de cálculo en fechas inválidas
        }
      }
    }

    int hours = totalDuration.inHours;
    int minutes = totalDuration.inMinutes.remainder(60);

    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Componente reutilizable para las tarjetas de estadísticas
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras se obtienen los datos de la API
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    // Manejo de estado en caso de que no se pueda cargar el usuario
    if (_user == null) {
      return const Center(
        child: Text(
          'Could not load user profile.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Foto de perfil circular (Avatar)
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Información principal del usuario
          Text(
            _user!.username,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _user!.email,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Etiqueta de suscripción (Premium o Gratuito)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _user!.isPremium
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _user!.isPremium ? Colors.amber : Colors.grey,
              ),
            ),
            child: Text(
              _user!.isPremium ? 'PRO Member' : 'Free Plan',
              style: TextStyle(
                color: _user!.isPremium ? Colors.amber : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Sección de Estadísticas (Dashboard)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grid con las métricas usando el componente reutilizable
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total Workouts',
                _workouts.length.toString(),
                Icons.fitness_center,
                Colors.blueAccent,
              ),
              _buildStatCard(
                'Time Trained',
                _calculateTotalTime(),
                Icons.timer,
                Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

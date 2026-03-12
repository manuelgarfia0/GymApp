import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/auth_dependencies.dart';
import '../../workouts/presentation/screens/exercises_screen.dart';
import '../../workouts/presentation/screens/active_workout_screen.dart';
import '../../workouts/presentation/screens/workout_detail_screen.dart';
import '../../workouts/presentation/screens/create_routine_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../workouts/workout_dependencies.dart';
import '../../workouts/domain/entities/workout.dart';
import '../../workouts/domain/entities/routine.dart';
import '../../workouts/domain/entities/exercise.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Usar use cases en lugar de servicios
  late final getWorkoutHistoryUseCase =
      WorkoutDependencies.getWorkoutHistoryUseCase;
  late final getRoutinesUseCase = WorkoutDependencies.getRoutinesUseCase;

  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final token = prefs.getString('jwt_token');

    print('🔍 HomeScreen: Loading user data');
    print('🔍 HomeScreen: User ID = $userId');
    print('🔍 HomeScreen: Has token = ${token != null}');
    if (token != null) {
      print('🔍 HomeScreen: Token preview = ${token.substring(0, 20)}...');
    }

    setState(() {
      _userId = userId;
    });
  }

  Future<void> _logout() async {
    try {
      // Usar el repositorio de autenticación para logout
      final authRepository = AuthDependencies.repository;
      await authRepository.logout();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LoginScreen(loginUseCase: AuthDependencies.loginUseCase),
          ),
        );
      }
    } catch (e) {
      print('⚠️ HomeScreen: Error durante logout: $e');
      // Incluso si hay error, navegar al login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LoginScreen(loginUseCase: AuthDependencies.loginUseCase),
          ),
        );
      }
    }
  }

  // Formatear la fecha tipo Hevy (Ej: "Today, 18:30" o "Oct 24, 2023")
  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today, ${DateFormat('HH:mm').format(date)}";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday, ${DateFormat('HH:mm').format(date)}";
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Pestaña principal (WORKOUT)
  Widget _buildWorkoutsTab() {
    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () async {
        setState(() {}); // Recarga la UI
      },
      child: CustomScrollView(
        slivers: [
          // 1. QUICK START WORKOUT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Start',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Start Empty Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveWorkoutScreen(
                              selectedExercises: [],
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. MY ROUTINES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Routines',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRoutineScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: const Text(
                      'Create New',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de rutinas
          FutureBuilder<List<Routine>>(
            future: _userId > 0
                ? getRoutinesUseCase(_userId)
                : Future.value([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                );
              }

              final routines = snapshot.data ?? [];
              if (routines.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No routines yet. Create your first routine!',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final routine = routines[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      color: const Color(0xFF2A2A2A),
                      child: ListTile(
                        title: Text(
                          routine.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${routine.exercises.length} exercises',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                        onTap: () {
                          // Convertir RoutineExercise a Exercise para ActiveWorkoutScreen
                          final exercises = routine.exercises.map((
                            routineExercise,
                          ) {
                            return Exercise(
                              id: routineExercise.exerciseId,
                              name: routineExercise.exerciseName ?? '',
                              description: '', // Valor por defecto
                              primaryMuscle: '', // Valor por defecto
                              category: '', // Valor por defecto
                              secondaryMuscles: [], // Valor por defecto
                            );
                          }).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActiveWorkoutScreen(
                                selectedExercises: exercises,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                    ),
                  );
                }, childCount: routines.length),
              );
            },
          ),

          // 3. RECENT WORKOUTS
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
              child: Text(
                'Recent Workouts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Lista de workouts recientes
          FutureBuilder<List<Workout>>(
            future: _userId > 0
                ? getWorkoutHistoryUseCase(_userId)
                : Future.value([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                );
              }

              final workouts = snapshot.data ?? [];
              if (workouts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No workouts yet. Start your first workout!',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Mostrar solo los últimos 5 workouts
              final recentWorkouts = workouts.take(5).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final workout = recentWorkouts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      color: const Color(0xFF2A2A2A),
                      child: ListTile(
                        title: Text(
                          workout.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(workout.startTime),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutDetailScreen(workout: workout),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }, childCount: recentWorkouts.length),
              );
            },
          ),

          // Espaciado final
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Progressive',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildWorkoutsTab(),
          const ExercisesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/features/auth/screens/login_screen.dart';
import 'package:gym_app/features/workouts/screens/exercises_screen.dart';
import 'package:gym_app/features/workouts/screens/active_workout_screen.dart';
import 'package:gym_app/features/workouts/screens/workout_detail_screen.dart';
import 'package:gym_app/features/workouts/screens/create_routine_screen.dart';
import 'package:gym_app/features/profile/screens/profile_screen.dart';
import 'package:gym_app/features/workouts/services/workout_service.dart';
import 'package:gym_app/features/workouts/services/routine_service.dart';
import 'package:gym_app/features/workouts/models/workout.dart';
import 'package:gym_app/features/workouts/models/routine.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final WorkoutService _workoutService = WorkoutService();
  final RoutineService _routineService = RoutineService();
  
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id') ?? 0;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // --- WIDGET PARA FORMATEAR LA FECHA TIPO HEVY (Ej: "Today, 18:30" o "Oct 24, 2023") ---
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return "Unknown Date";
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return "Today, ${DateFormat('HH:mm').format(date)}";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return "Yesterday, ${DateFormat('HH:mm').format(date)}";
      }
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // --- PESTAÑA PRINCIPAL (WORKOUT) ---
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
                  const Text('Quick Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text('Start Empty Workout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveWorkoutScreen(selectedExercises: []),
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
                  const Text('My Routines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateRoutineScreen()),
                      ).then((value) {
                        if (value == true) setState(() {}); 
                      });
                    }, 
                  )
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _userId == 0 
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              : FutureBuilder<List<RoutineDTO>>(
                  future: _routineService.getUserRoutines(_userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No routines found. Create one to get started.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    final routines = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: routines.length,
                      itemBuilder: (context, index) {
                        final routine = routines[index];
                        String exercisesList = routine.exercises.map((e) => e.exerciseName ?? 'Exercise').join(', ');
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // Iniciar la rutina
                              final allWorkouts = await _workoutService.getUserWorkouts(_userId);
                              WorkoutDTO? previousWorkout;
                              try {
                                previousWorkout = allWorkouts.firstWhere((w) => w.routineId == routine.id);
                              } catch (e) {
                                previousWorkout = null; 
                              }

                              if (!mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActiveWorkoutScreen(
                                    selectedExercises: const [], 
                                    baseRoutine: routine,        
                                    previousWorkout: previousWorkout,
                                  ),
                                ),
                              ).then((_) => setState(() {})); 
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        routine.name, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), 
                                      ),
                                      const Icon(Icons.play_arrow, color: Colors.blueAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exercisesList, 
                                    style: const TextStyle(color: Colors.grey, fontSize: 14), 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
          ),

          // 3. HISTORY / ACTIVITY
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          SliverToBoxAdapter(
            child: _userId == 0 
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<WorkoutDTO>>(
                future: _workoutService.getUserWorkouts(_userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No workouts logged yet. Complete a workout to see it here.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final workouts = snapshot.data!.reversed.toList(); 

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      String formattedDate = _formatDate(workout.startTime);
                      
                      // Calculamos total de series (volumen)
                      int totalSets = workout.sets.length;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => WorkoutDetailScreen(workout: workout))
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blueAccent,
                                      child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                          const SizedBox(height: 4),
                                          Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Resumen del entreno (Como en Hevy)
                                Row(
                                  children: [
                                    const Icon(Icons.format_list_bulleted, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('$totalSets sets', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    const Text('Completed', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)), // Espacio al final
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildWorkoutsTab(), 
      const ExercisesScreen(),
      const ProfileScreen(), 
    ];

    return Scaffold(
      // Top bar limpio sin color de fondo llamativo
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Workout' : _currentIndex == 1 ? 'Exercises' : 'Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          if (_currentIndex == 2) // Solo mostrar botón logout en el perfil
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _logout,
            )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Exercises'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/screens/login_screen.dart';
import 'package:gym_app/screens/exercises_screen.dart';
import 'package:gym_app/screens/active_workout_screen.dart';
import 'package:gym_app/screens/workout_detail_screen.dart';
import 'package:gym_app/screens/create_routine_screen.dart';
import 'package:gym_app/services/workout_service.dart';
import 'package:gym_app/services/routine_service.dart';
import 'package:gym_app/models/workout.dart';
import 'package:gym_app/models/routine.dart';
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

  Widget _buildWorkoutsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER: Empezar entrenamiento rápido (Libre)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          color: const Color(0xFF1A1A1A),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Quick Workout', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
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
            ],
          ),
        ),

        // 2. MY ROUTINES
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Routines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateRoutineScreen()),
                  ).then((value) {
                    if (value == true) setState(() {}); 
                  });
                }, 
                child: const Text('+ New', style: TextStyle(color: Colors.blueAccent)),
              )
            ],
          ),
        ),
        
        // Carrusel Horizontal de Rutinas
        SizedBox(
          height: 140,
          child: _userId == 0 
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<RoutineDTO>>(
                future: _routineService.getUserRoutines(_userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No routines created yet.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final routines = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      String exercisesList = routine.exercises.map((e) => e.exerciseName ?? 'Exercise').join(', ');
                      
                      return Container(
                        width: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Loading ${routine.name}...'), duration: const Duration(seconds: 1)),
                              );

                              // 1. Descargamos el historial completo para buscar si ya hizo esta rutina
                              final allWorkouts = await _workoutService.getUserWorkouts(_userId);
                              
                              // 2. Buscamos el entrenamiento más reciente asociado a este ID de rutina
                              WorkoutDTO? previousWorkout;
                              try {
                                previousWorkout = allWorkouts.firstWhere((w) => w.routineId == routine.id);
                              } catch (e) {
                                previousWorkout = null; // No hay historial previo
                              }

                              if (!mounted) return;

                              // 3. Abrimos el ActiveWorkoutScreen enviándole tanto la plantilla como los pesos del pasado
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
                                  Text(
                                    routine.name, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exercisesList, 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12), 
                                    maxLines: 3, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
        ),

        const Divider(height: 32),

        // 3. HISTORY
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),

        Expanded(
          child: _userId == 0 
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<WorkoutDTO>>(
              future: _workoutService.getUserWorkouts(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No workouts logged yet.', style: TextStyle(color: Colors.grey)),
                  );
                }

                // Invertimos la lista para mostrar primero lo más reciente
                final workouts = snapshot.data!.reversed.toList(); 

                return ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    
                    String formattedDate = "Unknown Date";
                    String durationStr = ""; 

                    if (workout.startTime.isNotEmpty) {
                      try {
                        DateTime parsedStart = DateTime.parse(workout.startTime);
                        formattedDate = DateFormat('MM/dd/yyyy - HH:mm').format(parsedStart);

                        // Cálculo del tiempo en formato HH:MM:SS
                        if (workout.endTime != null && workout.endTime!.isNotEmpty) {
                          DateTime parsedEnd = DateTime.parse(workout.endTime!);
                          Duration diff = parsedEnd.difference(parsedStart);
                          
                          int hours = diff.inHours;
                          int minutes = diff.inMinutes.remainder(60);
                          int seconds = diff.inSeconds.remainder(60);
                          
                          // Convertimos a string asegurando que siempre tengan 2 dígitos (ej: "05" en vez de "5")
                          String hStr = hours.toString().padLeft(2, '0');
                          String mStr = minutes.toString().padLeft(2, '0');
                          String sStr = seconds.toString().padLeft(2, '0');
                          
                          // Si quisieras ocultar las horas cuando son 00, sería: durationStr = hours > 0 ? "$hStr:$mStr:$sStr" : "$mStr:$sStr";
                          // Pero como pediste HH:MM:SS, lo mostramos completo:
                          durationStr = "$hStr:$mStr:$sStr";
                        }
                      } catch (e) {
                        formattedDate = workout.startTime;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFF1E1E1E),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // Mostramos fecha y duración
                        subtitle: Text(
                          durationStr.isNotEmpty ? '$formattedDate  •  ⏱ $durationStr' : formattedDate, 
                          style: const TextStyle(color: Colors.grey)
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => WorkoutDetailScreen(workout: workout))
                          );
                        },
                      ),
                    );
                  },
                );
              },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildWorkoutsTab(), 
      const ExercisesScreen(),
      const Center(child: Text('Profile', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
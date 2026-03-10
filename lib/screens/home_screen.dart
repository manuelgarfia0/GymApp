import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/screens/login_screen.dart';
import 'package:gym_app/screens/exercises_screen.dart';
import 'package:gym_app/screens/exercise_selection_screen.dart';
import 'package:gym_app/services/workout_service.dart';
import 'package:gym_app/models/workout.dart';
import 'package:intl/intl.dart'; // Para formatear fechas bonitas

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final WorkoutService _workoutService = WorkoutService();
  int _userId = 0; // Guardaremos aquí el ID del usuario logueado

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Cargamos el ID del usuario al iniciar la pantalla
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

  // --- WIDGET DE LA PESTAÑA DE WORKOUTS ---
  Widget _buildWorkoutsTab() {
    return Column(
      children: [
        // 1. Zona superior: Botón de Iniciar Entrenamiento
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(Icons.fitness_center, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Iniciar Entrenamiento', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Navegamos a la selección de ejercicios. 
                  // Usamos then() para recargar el historial cuando volvamos.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
                  ).then((_) => setState(() {})); 
                },
              ),
            ],
          ),
        ),
        
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Historial', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),

        // 2. Zona inferior: Lista del historial del usuario
        Expanded(
          child: _userId == 0 
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<WorkoutDTO>>(
              future: _workoutService.getUserWorkouts(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar historial', style: TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No has registrado ningún entrenamiento aún.', style: TextStyle(color: Colors.grey)),
                  );
                }

                final workouts = snapshot.data!.reversed.toList(); // Invertimos para ver el más nuevo arriba

                return ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    
                    // Formatear la fecha que nos manda Java a algo legible (ej: 24/10/2023)
                    String formattedDate = "Fecha desconocida";
                    if (workout.startTime.isNotEmpty) {
                      try {
                        DateTime parsedDate = DateTime.parse(workout.startTime);
                        formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(parsedDate);
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
                        subtitle: Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
    // Definimos qué widget se muestra en cada pestaña
    final List<Widget> screens = [
      _buildWorkoutsTab(), // La función que acabamos de crear
      const ExercisesScreen(),
      const Center(child: Text('Profile Settings', style: TextStyle(fontSize: 24))),
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Ejercicios'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
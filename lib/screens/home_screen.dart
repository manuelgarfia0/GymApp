import 'package:flutter/material.dart';
import 'package:gym_app/screens/active_workout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/screens/login_screen.dart';
import 'package:gym_app/screens/exercises_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variable para saber qué pestaña está seleccionada (0 = Workouts, 1 = Exercises, 2 = Profile)
  int _selectedIndex = 0;

  // Las 3 pantallas que se mostrarán en el centro
  final List<Widget> _screens = [
    // Pestaña 0: Workouts
    Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Iniciar Entrenamiento Vacío', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Navegamos a la nueva pantalla de entrenamiento
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen()),
                  );
                },
              ),
            ],
          ),
        );
      }
    ),
    
    // Pestaña 1: La lista de ejercicios
    const ExercisesScreen(),
    
    // Pestaña 2: Profile
    const Center(child: Text('Profile Settings', style: TextStyle(fontSize: 24))),
  ];

  // Función para cerrar sesión (la movemos aquí porque el botón estará en el AppBar general)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Función que se ejecuta al tocar un icono de la barra inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          // Solo mostramos el botón de Logout si estamos en la pestaña Profile (índice 2)
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _logout,
            )
        ],
      ),
      
      // El cuerpo principal cambia dependiendo de _selectedIndex
      body: _screens[_selectedIndex],
      
      // La barra de navegación mágica de Flutter
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex, // Le decimos cuál está activa
        onTap: _onItemTapped, // Llama a la función al tocar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
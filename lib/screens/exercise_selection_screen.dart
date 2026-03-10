import 'package:flutter/material.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/services/exercise_service.dart';
import 'package:gym_app/screens/active_workout_screen.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<Exercise>> _futureExercises;
  
  // Aquí guardamos los ejercicios que el usuario va marcando
  final List<Exercise> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _futureExercises = _exerciseService.getExercises();
  }

  // Función para marcar/desmarcar un ejercicio
  void _toggleSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise); // Si ya estaba, lo quitamos
      } else {
        _selectedExercises.add(exercise); // Si no estaba, lo añadimos
      }
    });
  }

    void _confirmSelection() {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona al menos un ejercicio')),
      );
      return;
    }

    // Navegamos a la pantalla de entrenamiento pasándole los ejercicios elegidos
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(selectedExercises: _selectedExercises),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Ejercicios'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _futureExercises,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay ejercicios disponibles.'));
          }

          final exercises = snapshot.data!;
          
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final isSelected = _selectedExercises.contains(exercise);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isSelected ? Colors.blueAccent.withOpacity(0.2) : const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[800],
                    child: Icon(isSelected ? Icons.check : Icons.fitness_center, color: Colors.white),
                  ),
                  title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${exercise.primaryMuscle} • ${exercise.equipment}'),
                  onTap: () => _toggleSelection(exercise),
                ),
              );
            },
          );
        },
      ),
      // Botón flotante abajo a la derecha que solo aparece si has seleccionado algo
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmSelection,
              backgroundColor: Colors.blueAccent,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text('Añadir (${_selectedExercises.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
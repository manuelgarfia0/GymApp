import 'package:flutter/material.dart';
import 'package:gym_app/features/workouts/models/exercise.dart';
import 'package:gym_app/features/workouts/services/exercise_service.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<Exercise>> _futureExercises;

  // Lista con TODOS los ejercicios
  List<Exercise> _allExercises = [];
  // Lista filtrada que es la que realmente mostramos en pantalla
  List<Exercise> _filteredExercises = [];
  
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureExercises = _exerciseService.getExercises().then((exercises) {
      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises; // Al principio mostramos todos
      });
      return exercises;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN QUE FILTRA LA LISTA EN TIEMPO REAL ---
  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _allExercises;
      } else {
        _filteredExercises = _allExercises.where((ex) {
          // Buscamos ignorando mayúsculas/minúsculas
          return ex.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Add Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterExercises, // Llama a la función cada vez que el usuario teclea
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search exercise...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // Botón "X" para borrar el texto rápidamente
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterExercises('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // --- LISTA DE RESULTADOS ---
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _futureExercises,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No exercises found', style: TextStyle(color: Colors.grey)),
                  );
                }

                // Si el usuario busca algo que no existe
                if (_filteredExercises.isEmpty) {
                  return const Center(
                    child: Text('No results match your search', style: TextStyle(color: Colors.grey)),
                  );
                }

                // Dibujamos la lista usando la _filteredExercises
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredExercises.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey[850], height: 1),
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${exercise.primaryMuscleName} • ${exercise.equipmentName}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                      trailing: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                      onTap: () {
                        // Devolvemos el ejercicio a la pantalla de entrenamiento
                        Navigator.pop(context, exercise);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
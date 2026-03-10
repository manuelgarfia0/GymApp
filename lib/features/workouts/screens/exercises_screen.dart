import 'package:flutter/material.dart';
import 'package:gym_app/features/workouts/models/exercise.dart';
import 'package:gym_app/features/workouts/services/exercise_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<Exercise>> _futureExercises;

  // Listas para la búsqueda
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureExercises = _exerciseService.getExercises().then((exercises) {
      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
      });
      return exercises;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE BÚSQUEDA ---
  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _allExercises;
      } else {
        _filteredExercises = _allExercises.where((ex) {
          return ex.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- BARRA DE BÚSQUEDA ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterExercises,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterExercises('');
                        // Ocultamos el teclado al borrar todo
                        FocusScope.of(context).unfocus();
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

        // --- LISTA DE EJERCICIOS EXPANDIBLES ---
        Expanded(
          child: FutureBuilder<List<Exercise>>(
            future: _futureExercises,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No exercises available', style: TextStyle(color: Colors.grey)));
              }

              // Si la búsqueda no da resultados
              if (_filteredExercises.isEmpty) {
                return const Center(
                  child: Text('No results match your search', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80), // Margen inferior para que no lo tape el BottomNavBar
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  // USAMOS LA LISTA FILTRADA AQUÍ
                  final exercise = _filteredExercises[index];
                  
                  Widget secondaryMusclesWidget = const SizedBox.shrink();
                  if (exercise.secondaryMuscleNames.isNotEmpty) {
                    secondaryMusclesWidget = Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 6.0,
                        children: exercise.secondaryMuscleNames.map((muscle) {
                          return Chip(
                            label: Text(muscle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            backgroundColor: Colors.grey[850],
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: Colors.blueAccent,
                        collapsedIconColor: Colors.grey,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${exercise.primaryMuscleName} • ${exercise.equipmentName}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        children: [
                          Container(
                            color: const Color(0xFF121212),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Instructions',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exercise.description,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
                                ),
                                
                                if (exercise.secondaryMuscleNames.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Secondary Muscles',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                  secondaryMusclesWidget,
                                ],
                              ],
                            ),
                          )
                        ],
                      ),
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
}
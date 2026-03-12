import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/use_cases/get_exercises.dart';
import '../../workout_dependencies.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late final GetExercises _getExercisesUseCase;
  late Future<List<Exercise>> _futureExercises;

  // List with ALL exercises
  List<Exercise> _allExercises = [];
  // Filtered list that is actually shown on screen
  List<Exercise> _filteredExercises = [];

  // Controller for search field
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize use case with dependencies
    _getExercisesUseCase = WorkoutDependencies.getExercisesUseCase;

    _futureExercises = _getExercisesUseCase()
        .then((exercises) {
          setState(() {
            _allExercises = exercises;
            _filteredExercises = exercises; // Initially show all
          });
          return exercises;
        })
        .catchError((error) {
          // Handle errors gracefully in the UI
          if (mounted) {
            String errorMessage = 'Failed to load exercises';

            if (error is AuthenticationFailure) {
              errorMessage = error.message;
            } else if (error is NetworkFailure) {
              errorMessage = error.message;
            } else if (error is ValidationFailure) {
              errorMessage = error.message;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: error is NetworkFailure
                    ? Colors.orange
                    : Colors.red,
                duration: const Duration(seconds: 4),
                action: error is NetworkFailure
                    ? SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            _futureExercises = _getExercisesUseCase().then((
                              exercises,
                            ) {
                              setState(() {
                                _allExercises = exercises;
                                _filteredExercises = exercises;
                              });
                              return exercises;
                            });
                          });
                        },
                      )
                    : null,
              ),
            );
          }

          // Return empty list to prevent further errors
          return <Exercise>[];
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function that filters the list in real time
  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _allExercises;
      } else {
        _filteredExercises = _allExercises.where((ex) {
          // Search ignoring case
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
        title: const Text(
          'Add Exercise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged:
                  _filterExercises, // Call function every time user types
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search exercise...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // "X" button to clear text quickly
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

          // Results list
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _futureExercises,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No exercises found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // If user searches for something that doesn't exist
                if (_filteredExercises.isEmpty) {
                  return const Center(
                    child: Text(
                      'No results match your search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Draw the list using _filteredExercises
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredExercises.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey[850], height: 1),
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${exercise.primaryMuscle} • ${exercise.category}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blueAccent,
                      ),
                      onTap: () {
                        // Return the exercise to the workout screen
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

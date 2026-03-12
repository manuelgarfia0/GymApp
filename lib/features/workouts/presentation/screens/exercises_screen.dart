import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/use_cases/get_exercises.dart';
import '../../workout_dependencies.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late final GetExercises _getExercisesUseCase;
  late Future<List<Exercise>> _futureExercises;

  // Lists for search functionality
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];

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
            _filteredExercises = exercises;
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

  // Search logic
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
        // Search bar
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
                        // Hide keyboard when clearing
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

        // Exercise list
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
                    'No exercises available',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // If search returns no results
              if (_filteredExercises.isEmpty) {
                return const Center(
                  child: Text(
                    'No results match your search',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 80,
                ), // Bottom margin for BottomNavBar
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  // Use filtered list here
                  final exercise = _filteredExercises[index];

                  Widget secondaryMusclesWidget = const SizedBox.shrink();
                  if (exercise.secondaryMuscles.isNotEmpty) {
                    secondaryMusclesWidget = Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 6.0,
                        children: exercise.secondaryMuscles.map((muscle) {
                          return Chip(
                            label: Text(
                              muscle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            backgroundColor: Colors.grey[850],
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,

                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: Colors.blueAccent,
                        collapsedIconColor: Colors.grey,
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
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exercise.description ??
                                      'No description available', // Maneja descripción nula
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),

                                if (exercise.secondaryMuscles.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Secondary Muscles',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  secondaryMusclesWidget,
                                ],
                              ],
                            ),
                          ),
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

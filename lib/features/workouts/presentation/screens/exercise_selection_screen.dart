import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/use_cases/get_exercises.dart';
import '../../workout_dependencies.dart';
import '../widgets/exercise_media_viewer.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late final GetExercises _getExercisesUseCase;
  late Future<List<Exercise>> _futureExercises;

  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedMuscle = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getExercisesUseCase = WorkoutDependencies.getExercisesUseCase;
    _futureExercises = _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _availableMuscles {
    final muscles =
        _allExercises
            .map((ex) => ex.primaryMuscle?.trim() ?? '')
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...muscles];
  }

  Future<List<Exercise>> _loadExercises() {
    return _getExercisesUseCase()
        .then((exercises) {
          if (mounted) {
            setState(() {
              _allExercises = exercises;
              _applyFilters();
            });
          }
          return exercises;
        })
        .catchError((error) {
          _showLoadError(error);
          return <Exercise>[];
        });
  }

  void _showLoadError(Object error) {
    if (!mounted) return;

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
        backgroundColor: error is NetworkFailure ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 4),
        action: error is NetworkFailure
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _futureExercises = _loadExercises();
                  });
                },
              )
            : null,
      ),
    );
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    _filteredExercises = _allExercises.where((ex) {
      final matchesMuscle =
          _selectedMuscle == 'All' ||
          (ex.primaryMuscle?.toLowerCase() == _selectedMuscle.toLowerCase());
      if (!matchesMuscle) return false;
      if (query.isEmpty) return true;

      return ex.name.toLowerCase().contains(query) ||
          (ex.primaryMuscle?.toLowerCase().contains(query) ?? false) ||
          (ex.category?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _onSearchChanged(String _) {
    setState(_applyFilters);
  }

  void _onMuscleSelected(String muscle) {
    if (_selectedMuscle == muscle) return;
    setState(() {
      _selectedMuscle = muscle;
      _applyFilters();
    });
  }

  Widget _buildMuscleFilterBar() {
    final muscles = _availableMuscles;
    if (muscles.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: muscles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final muscle = muscles[index];
          final isSelected = _selectedMuscle == muscle;
          return ChoiceChip(
            label: Text(muscle),
            selected: isSelected,
            onSelected: (_) => _onMuscleSelected(muscle),
            selectedColor: Colors.blueAccent,
            backgroundColor: const Color(0xFF1E1E1E),
            side: BorderSide(
              color: isSelected ? Colors.blueAccent : Colors.grey[800]!,
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[300],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  String _formatExerciseSubtitle(Exercise exercise) {
    final parts = <String>[
      if (exercise.primaryMuscle != null &&
          exercise.primaryMuscle!.trim().isNotEmpty)
        exercise.primaryMuscle!,
      if (exercise.category != null && exercise.category!.trim().isNotEmpty)
        exercise.category!,
      if (exercise.secondaryMuscles.isNotEmpty)
        '+ ${exercise.secondaryMuscles.join(', ')}',
    ];
    return parts.join(' • ');
  }

  void _showExerciseDetails(Exercise exercise) {
    showExerciseDetailSheet(
      context,
      exercise,
      onSelect: () => Navigator.pop(context, exercise),
    );
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, muscle or equipment...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
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
          _buildMuscleFilterBar(),
          const SizedBox(height: 6),
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

                if (_filteredExercises.isEmpty) {
                  return const Center(
                    child: Text(
                      'No results match your search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

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
                      leading: ExerciseThumbnail(
                        exercise: exercise,
                        onTap: () => _showExerciseDetails(exercise),
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
                          _formatExerciseSubtitle(exercise),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: Colors.grey[400],
                            ),
                            tooltip: 'Exercise details',
                            onPressed: () => _showExerciseDetails(exercise),
                          ),
                          const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, exercise),
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

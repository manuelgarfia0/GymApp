import 'package:flutter/material.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/services/exercise_service.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<Exercise>> _futureExercises;

  List<Exercise> _allExercises = [];

  @override
  void initState() {
    super.initState();
    _futureExercises = _exerciseService.getExercises().then((exercises) {
      _allExercises = exercises;
      return exercises;
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
      body: FutureBuilder<List<Exercise>>(
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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _allExercises.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[850], height: 1),
            itemBuilder: (context, index) {
              final exercise = _allExercises[index];
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
                  Navigator.pop(context, exercise);
                },
              );
            },
          );
        },
      ),
    );
  }
}
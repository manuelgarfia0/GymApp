import 'package:flutter/material.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/services/exercise_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<Exercise>> _futureExercises;

  @override
  void initState() {
    super.initState();
    _futureExercises = _exerciseService.getExercises();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Exercise>>(
      future: _futureExercises,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No exercises available', style: TextStyle(color: Colors.grey)));
        }

        final exercises = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            
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
    );
  }
}
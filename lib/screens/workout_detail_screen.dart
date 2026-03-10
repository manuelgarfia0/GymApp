import 'package:flutter/material.dart';
import 'package:gym_app/models/workout.dart';
import 'package:intl/intl.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutDTO workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  // Función para agrupar las series por ejercicio
  List<Map<String, dynamic>> _getGroupedExercises() {
    Map<int, Map<String, dynamic>> grouped = {};

    for (var set in workout.sets) {
      if (!grouped.containsKey(set.exerciseId)) {
        grouped[set.exerciseId] = {
          'name': set.exerciseName ?? 'Unknown Exercise',
          'sets': <WorkoutSetDTO>[],
        };
      }
      grouped[set.exerciseId]!['sets'].add(set);
    }

    return grouped.values.toList();
  }

  // ¡MODIFICADO! Ahora devuelve formato HH:MM:SS
  String _calculateDuration() {
    if (workout.startTime.isEmpty || workout.endTime == null || workout.endTime!.isEmpty) {
      return "--:--:--";
    }

    try {
      DateTime start = DateTime.parse(workout.startTime);
      DateTime end = DateTime.parse(workout.endTime!);
      
      Duration difference = end.difference(start);
      
      int hours = difference.inHours;
      int minutes = difference.inMinutes.remainder(60);
      int seconds = difference.inSeconds.remainder(60);
      
      String hStr = hours.toString().padLeft(2, '0');
      String mStr = minutes.toString().padLeft(2, '0');
      String sStr = seconds.toString().padLeft(2, '0');

      return "$hStr:$mStr:$sStr";
    } catch (e) {
      return "--:--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatear la fecha para el título de la página
    String formattedDate = "Unknown Date";
    
    if (workout.startTime.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(workout.startTime);
        formattedDate = DateFormat('EEEE, MMM d, yyyy').format(parsedDate); // Ej: Monday, Oct 24, 2023
      } catch (e) {
        formattedDate = workout.startTime;
      }
    }

    final groupedExercises = _getGroupedExercises();
    final durationStr = _calculateDuration();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Workout Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // HEADER (Resumen del entrenamiento)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1E1E1E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                const SizedBox(height: 16),
                Text(
                  workout.name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Fila con iconos de Reloj y Series totales
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      durationStr, // Muestra 01:15:30
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.fitness_center, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${workout.sets.length} Sets', 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // LISTA DE EJERCICIOS REALIZADOS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: groupedExercises.length,
              itemBuilder: (context, index) {
                final exercise = groupedExercises[index];
                final String exName = exercise['name'];
                final List<WorkoutSetDTO> exSets = exercise['sets'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Set', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('kg', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('Reps', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(color: Colors.grey),
                        
                        // Generamos las filas de las series
                        ...exSets.asMap().entries.map((entry) {
                          int setIndex = entry.key + 1;
                          WorkoutSetDTO s = entry.value;
                          
                          String weightStr = s.weight == s.weight.toInt() 
                            ? s.weight.toInt().toString() 
                            : s.weight.toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$setIndex', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                Text(weightStr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('${s.reps}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
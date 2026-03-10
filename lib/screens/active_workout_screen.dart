import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NUEVA IMPORTACIÓN
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/models/workout.dart';
import 'package:gym_app/services/workout_service.dart';

class ActiveSet {
  double? weight;
  int? reps;
  ActiveSet({this.weight, this.reps});
}

class ActiveExercise {
  final Exercise exercise;
  final List<ActiveSet> sets;
  ActiveExercise({required this.exercise, required this.sets});
}

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Exercise> selectedExercises;

  const ActiveWorkoutScreen({super.key, required this.selectedExercises});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final List<ActiveExercise> _activeExercises = [];
  final WorkoutService _workoutService = WorkoutService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var ex in widget.selectedExercises) {
      _activeExercises.add(ActiveExercise(exercise: ex, sets: [ActiveSet()]));
    }
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      _activeExercises[exerciseIndex].sets.add(ActiveSet());
    });
  }

  Future<void> _finishWorkout() async {
    setState(() { _isSaving = true; });

    final List<WorkoutSetDTO> setsToSend = [];
    int exerciseOrder = 1;

    for (var activeEx in _activeExercises) {
      int setNumber = 1;
      for (var s in activeEx.sets) {
        if (s.weight != null && s.reps != null) {
          setsToSend.add(WorkoutSetDTO(
            exerciseId: activeEx.exercise.id,
            exerciseOrder: exerciseOrder,
            setNumber: setNumber,
            weight: s.weight!,
            reps: s.reps!,
          ));
          setNumber++;
        }
      }
      if (setNumber > 1) {
        exerciseOrder++;
      }
    }

    if (setsToSend.isEmpty) {
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una serie válida.'), backgroundColor: Colors.red),
      );
      return;
    }

    // --- NUEVO: RECUPERAR EL ID DEL USUARIO ---
    final prefs = await SharedPreferences.getInstance();
    final int realUserId = prefs.getInt('user_id') ?? 1; // Leemos el ID que guardamos en el Login

    final request = WorkoutDTO(
      name: 'Entrenamiento de hoy',
      startTime: DateTime.now().toIso8601String(),
      userId: realUserId, // ¡AQUÍ USAMOS EL ID REAL!
      sets: setsToSend,
    );

    final success = await _workoutService.saveWorkout(request);

    setState(() { _isSaving = false; });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Entrenamiento guardado en la Base de Datos!'), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el entrenamiento.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento'),
        backgroundColor: Colors.blueAccent,
        actions: [
          _isSaving 
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : TextButton(
                onPressed: _finishWorkout,
                child: const Text('FINALIZAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
        ],
      ),
      body: ListView.builder(
        itemCount: _activeExercises.length,
        itemBuilder: (context, exerciseIndex) {
          final activeEx = _activeExercises[exerciseIndex];
          
          return Card(
            margin: const EdgeInsets.all(16.0),
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeEx.exercise.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('SET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('KG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('REPS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const Divider(),
                  ...List.generate(activeEx.sets.length, (setIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                            child: Text('${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(filled: true, fillColor: Color(0xFF2C2C2C), border: OutlineInputBorder(borderSide: BorderSide.none), hintText: '0'),
                              onChanged: (value) => activeEx.sets[setIndex].weight = double.tryParse(value),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(filled: true, fillColor: Color(0xFF2C2C2C), border: OutlineInputBorder(borderSide: BorderSide.none), hintText: '0'),
                              onChanged: (value) => activeEx.sets[setIndex].reps = int.tryParse(value),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _addSetToExercise(exerciseIndex),
                    icon: const Icon(Icons.add, color: Colors.blueAccent),
                    label: const Text('Añadir Serie', style: TextStyle(color: Colors.blueAccent)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
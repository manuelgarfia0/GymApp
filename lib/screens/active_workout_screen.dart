import 'package:flutter/material.dart';
import 'package:gym_app/models/exercise.dart'; // Importamos el modelo de Ejercicio
import 'package:gym_app/models/workout.dart';
import 'package:gym_app/services/workout_service.dart';

class ActiveSet {
  double? weight;
  int? reps;
  ActiveSet({this.weight, this.reps});
}

// Nueva clase para agrupar un Ejercicio con sus Series
class ActiveExercise {
  final Exercise exercise;
  final List<ActiveSet> sets;
  ActiveExercise({required this.exercise, required this.sets});
}

class ActiveWorkoutScreen extends StatefulWidget {
  // Recibimos los ejercicios seleccionados desde la pantalla anterior
  final List<Exercise> selectedExercises;

  const ActiveWorkoutScreen({super.key, required this.selectedExercises});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // Ahora tenemos una lista de "Ejercicios Activos", cada uno con sus series
  final List<ActiveExercise> _activeExercises = [];
  
  final WorkoutService _workoutService = WorkoutService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, creamos un bloque por cada ejercicio seleccionado
    // y le ponemos 1 serie vacía por defecto a cada uno.
    for (var ex in widget.selectedExercises) {
      _activeExercises.add(ActiveExercise(exercise: ex, sets: [ActiveSet()]));
    }
  }

  // Función para añadir una serie a un ejercicio específico
  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      _activeExercises[exerciseIndex].sets.add(ActiveSet());
    });
  }

  Future<void> _finishWorkout() async {
    setState(() { _isSaving = true; });

    final List<WorkoutSetDTO> setsToSend = [];
    int exerciseOrder = 1;

    // Recorremos cada ejercicio
    for (var activeEx in _activeExercises) {
      int setNumber = 1;
      
      // Recorremos las series de ese ejercicio
      for (var s in activeEx.sets) {
        // Solo enviamos las series que tengan peso y repeticiones
        if (s.weight != null && s.reps != null) {
          setsToSend.add(WorkoutSetDTO(
            exerciseId: activeEx.exercise.id, // ¡ID REAL DEL EJERCICIO!
            exerciseOrder: exerciseOrder,
            setNumber: setNumber,
            weight: s.weight!,
            reps: s.reps!,
          ));
          setNumber++;
        }
      }
      
      // Si el ejercicio tuvo alguna serie válida, aumentamos el orden para el siguiente
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

    final request = WorkoutDTO(
      name: 'Entrenamiento de hoy', // Más adelante dejaremos que el usuario lo escriba
      startTime: DateTime.now().toIso8601String(),
      userId: 1, // Sigue fijo por ahora
      sets: setsToSend,
    );

    final success = await _workoutService.saveWorkout(request);

    setState(() { _isSaving = false; });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Entrenamiento guardado en la Base de Datos!'), backgroundColor: Colors.green),
        );
        // Volvemos a la Home (pop 2 veces: salimos del entrenamiento y salimos de la selección de ejercicios)
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
      // Dibujamos una lista con todos los ejercicios seleccionados
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
                  // Nombre del Ejercicio
                  Text(
                    activeEx.exercise.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cabecera (Set | KG | Reps)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('SET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('KG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('REPS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const Divider(),
                  
                  // Series de este ejercicio
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
                  
                  // Botón de Añadir Serie para este ejercicio concreto
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
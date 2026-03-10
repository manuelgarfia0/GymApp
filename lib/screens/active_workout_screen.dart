import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/models/workout.dart';
import 'package:gym_app/models/routine.dart';
import 'package:gym_app/services/workout_service.dart';
import 'package:gym_app/screens/exercise_selection_screen.dart';

class ActiveSet {
  final String id;
  double? weight;
  int? reps;
  bool isCompleted;
  ActiveSet({this.weight, this.reps, this.isCompleted = false}) : id = UniqueKey().toString();
}

class ActiveExercise {
  final String id;
  final Exercise exercise;
  final List<ActiveSet> sets;
  ActiveExercise({required this.exercise, required this.sets}) : id = UniqueKey().toString();
}

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Exercise> selectedExercises;
  final RoutineDTO? baseRoutine;
  final WorkoutDTO? previousWorkout; 

  const ActiveWorkoutScreen({super.key, required this.selectedExercises, this.baseRoutine, this.previousWorkout});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final List<ActiveExercise> _activeExercises = [];
  final WorkoutService _workoutService = WorkoutService();
  
  late TextEditingController _workoutNameController;
  bool _isSaving = false;

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    String initialName = widget.baseRoutine?.name ?? "Today's Workout";
    _workoutNameController = TextEditingController(text: initialName);

    if (widget.previousWorkout != null && widget.baseRoutine != null) {
      var uniqueExerciseIds = widget.previousWorkout!.sets.map((s) => s.exerciseId).toSet().toList();

      for (var exId in uniqueExerciseIds) {
        var historySets = widget.previousWorkout!.sets.where((s) => s.exerciseId == exId).toList();
        
        String exerciseName = historySets.first.exerciseName ?? 'Unknown Exercise';
        Exercise mockExercise = Exercise(id: exId, name: exerciseName);

        List<ActiveSet> initialSets = historySets.map((oldSet) {
          return ActiveSet(
            weight: oldSet.weight > 0 ? oldSet.weight : null, 
            reps: oldSet.reps > 0 ? oldSet.reps : null,
            isCompleted: false 
          );
        }).toList();

        _activeExercises.add(ActiveExercise(exercise: mockExercise, sets: initialSets));
      }

    } else if (widget.baseRoutine != null) {
      for (var routineEx in widget.baseRoutine!.exercises) {
        Exercise mockExercise = Exercise(
          id: routineEx.exerciseId,
          name: routineEx.exerciseName ?? 'Unknown Exercise',
        );

        int targetSets = routineEx.sets > 0 ? routineEx.sets : 1;
        int targetReps = routineEx.reps > 0 ? routineEx.reps : 10; 

        List<ActiveSet> initialSets = List.generate(
          targetSets, 
          (index) => ActiveSet(reps: targetReps) 
        );
        
        _activeExercises.add(ActiveExercise(exercise: mockExercise, sets: initialSets));
      }
    } else {
      for (var ex in widget.selectedExercises) {
        _activeExercises.add(ActiveExercise(exercise: ex, sets: [ActiveSet()]));
      }
    }

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _workoutNameController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() { _secondsElapsed++; });
    });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    String hoursStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    return '$hoursStr$minutesStr:$secondsStr';
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      var previousSet = _activeExercises[exerciseIndex].sets.last;
      _activeExercises[exerciseIndex].sets.add(ActiveSet(
        weight: previousSet.weight,
        reps: previousSet.reps, 
      ));
    });
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex) {
    setState(() {
      _activeExercises[exerciseIndex].sets[setIndex].isCompleted = 
          !_activeExercises[exerciseIndex].sets[setIndex].isCompleted;
    });
  }

  Future<void> _navigateToAddExercise() async {
    final Exercise? selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
    );

    if (selectedExercise != null) {
      if (_activeExercises.any((e) => e.exercise.id == selectedExercise.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedExercise.name} is already in the workout.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      setState(() {
        _activeExercises.add(ActiveExercise(
          exercise: selectedExercise,
          sets: [ActiveSet()],
        ));
      });
    }
  }

  // POPUP 1: PREGUNTA AL DARLE A LA 'X' (CANCELAR ENTRENAMIENTO)
  Future<bool> _askToCancelWorkout() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Cancel Workout?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to cancel this workout? All progress will be lost.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // No salir
              child: const Text('NO, RESUME', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Sí salir
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('CANCEL WORKOUT', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // POPUP 2: PREGUNTA AL DARLE A 'FINISH' (GUARDAR ENTRENAMIENTO)
  Future<bool> _askToFinishWorkout() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Finish Workout?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you ready to complete and save this workout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // No guardar aún
              child: const Text('NOT YET', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Sí guardar
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('FINISH', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _attemptFinishWorkout() async {
    FocusScope.of(context).unfocus(); 

    if (_activeExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one exercise.'), backgroundColor: Colors.orange));
      return;
    }

    final List<WorkoutSetDTO> setsToSend = [];
    int exerciseOrder = 1;

    for (var activeEx in _activeExercises) {
      bool hasAtLeastOneValidSet = false;
      int setNumber = 1;

      for (var s in activeEx.sets) {
        if (s.isCompleted && s.weight != null && s.reps != null) {
          hasAtLeastOneValidSet = true;
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

      if (!hasAtLeastOneValidSet) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You left "${activeEx.exercise.name}" empty. Please complete at least one set or remove the exercise.'), backgroundColor: Colors.red));
        return; 
      }
      exerciseOrder++;
    }

    // AÑADIMOS LA PREGUNTA DE CONFIRMACIÓN DE FINISH
    bool shouldFinish = await _askToFinishWorkout();
    if (!shouldFinish) {
      return; // Si dice que no, se queda en la pantalla
    }

    setState(() { _isSaving = true; });

    final prefs = await SharedPreferences.getInstance();
    final int realUserId = prefs.getInt('user_id') ?? 1;
    String finalName = _workoutNameController.text.trim();
    if (finalName.isEmpty) finalName = "Today's Workout";

        // Capturamos el momento exacto en el que le dio a FINISH
    final now = DateTime.now();
    // Calculamos a qué hora empezó restando los segundos del cronómetro
    final start = now.subtract(Duration(seconds: _secondsElapsed));

        // ¡NUEVO! Calculamos la fecha y hora actual como endTime
    final String currentIsoTime = DateTime.now().toIso8601String();
    
    // Necesitamos el startTime real (hace cuánto empezó) para que el cálculo sea correcto
    // Restamos los segundos que han pasado a la hora actual
    final DateTime realStartTime = DateTime.now().subtract(Duration(seconds: _secondsElapsed));

    final request = WorkoutDTO(
      name: finalName,
      startTime: realStartTime.toIso8601String(), // Hora en la que abrió la pantalla
      endTime: currentIsoTime,                    // Hora en la que le dio a FINISH
      userId: realUserId,
      routineId: widget.baseRoutine?.id, 
      sets: setsToSend,
    );
    
    final workoutSuccess = await _workoutService.saveWorkout(request);

    setState(() { _isSaving = false; });

    if (workoutSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save workout.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Esto intercepta el botón de retroceso de Android también
      onWillPop: () async {
        bool cancel = await _askToCancelWorkout();
        return cancel;
      },
      child: Scaffold(
        appBar: AppBar(
          // CAMBIAMOS LA FLECHA DE ATRÁS POR UNA 'X'
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              bool cancel = await _askToCancelWorkout();
              if (cancel && mounted) {
                Navigator.pop(context); // Sale de la pantalla si confirma
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          actions: [
            _isSaving 
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : TextButton(
                  onPressed: _attemptFinishWorkout, // Llama a la nueva función con pregunta
                  child: const Text('FINISH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1A1A1A),
              child: TextField(
                controller: _workoutNameController,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Workout Name',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false, 
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _activeExercises.removeAt(oldIndex);
                    _activeExercises.insert(newIndex, item);
                  });
                },
                footer: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                itemCount: _activeExercises.length,
                itemBuilder: (context, exerciseIndex) {
                  final activeEx = _activeExercises[exerciseIndex];
                  
                  return Card(
                    key: Key(activeEx.id),
                    margin: const EdgeInsets.all(12.0),
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeEx.exercise.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _activeExercises.removeAt(exerciseIndex);
                                  });
                                },
                              ),
                              ReorderableDragStartListener(
                                index: exerciseIndex,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.drag_handle, color: Colors.grey, size: 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(width: 40, child: Text('SET', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                              SizedBox(width: 80, child: Text('KG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                              SizedBox(width: 80, child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                              SizedBox(width: 40, child: Icon(Icons.check, color: Colors.grey, size: 18)),
                            ],
                          ),
                          const Divider(color: Colors.grey),
                          ...List.generate(activeEx.sets.length, (setIndex) {
                            final currentSet = activeEx.sets[setIndex];
                            
                            String weightStr = '';
                            if (currentSet.weight != null && currentSet.weight! > 0) {
                              weightStr = currentSet.weight! == currentSet.weight!.toInt() 
                                ? currentSet.weight!.toInt().toString() 
                                : currentSet.weight!.toString();
                            }
                            
                            String repsStr = (currentSet.reps != null && currentSet.reps! > 0) 
                                ? currentSet.reps!.toString() 
                                : '';

                            return Dismissible(
                              key: Key(currentSet.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.redAccent.withOpacity(0.8),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                setState(() {
                                  activeEx.sets.removeAt(setIndex);
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
                                        child: Text('${setIndex + 1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: weightStr,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          filled: true, 
                                          fillColor: currentSet.isCompleted ? Colors.green.withOpacity(0.2) : const Color(0xFF2C2C2C), 
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), 
                                          hintText: '-',
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8)
                                        ),
                                        onChanged: (value) => currentSet.weight = double.tryParse(value),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: repsStr,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          filled: true, 
                                          fillColor: currentSet.isCompleted ? Colors.green.withOpacity(0.2) : const Color(0xFF2C2C2C), 
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), 
                                          hintText: '-',
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8)
                                        ),
                                        onChanged: (value) => currentSet.reps = int.tryParse(value),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.check_circle, 
                                          color: currentSet.isCompleted ? Colors.green : Colors.grey[700],
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          _toggleSetCompletion(exerciseIndex, setIndex);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _addSetToExercise(exerciseIndex),
                              icon: const Icon(Icons.add, color: Colors.blueAccent, size: 20),
                              label: const Text('Add Set', style: TextStyle(color: Colors.blueAccent)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
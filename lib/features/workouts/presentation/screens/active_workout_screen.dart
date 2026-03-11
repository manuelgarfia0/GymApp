import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/routine.dart';
import '../../domain/use_cases/save_workout.dart';
import '../../workout_dependencies.dart';
import 'exercise_selection_screen.dart';

class ActiveSet {
  final String id;
  double? weight;
  int? reps;
  bool isCompleted;
  ActiveSet({this.weight, this.reps, this.isCompleted = false})
    : id = UniqueKey().toString();
}

class ActiveExercise {
  final String id;
  final Exercise exercise;
  final List<ActiveSet> sets;
  int restSeconds;
  String notes;

  ActiveExercise({
    required this.exercise,
    required this.sets,
    this.restSeconds = 90,
    this.notes = '',
  }) : id = UniqueKey().toString();
}

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Exercise> selectedExercises;
  final Routine? baseRoutine;
  final Workout? previousWorkout;

  const ActiveWorkoutScreen({
    super.key,
    required this.selectedExercises,
    this.baseRoutine,
    this.previousWorkout,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final List<ActiveExercise> _activeExercises = [];
  late final SaveWorkout _saveWorkoutUseCase;

  late TextEditingController _workoutNameController;
  bool _isSaving = false;

  Timer? _workoutTimer;
  int _workoutSecondsElapsed = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();

    // Initialize use case with dependencies
    _saveWorkoutUseCase = WorkoutDependencies.saveWorkoutUseCase;

    String initialName = widget.baseRoutine?.name ?? "Today's Workout";
    _workoutNameController = TextEditingController(text: initialName);

    if (widget.previousWorkout != null && widget.baseRoutine != null) {
      _initializeFromPreviousWorkout();
    } else if (widget.baseRoutine != null) {
      _initializeFromRoutine();
    } else {
      _initializeFromSelectedExercises();
    }

    _startWorkoutTimer();
  }

  void _initializeFromPreviousWorkout() {
    var uniqueExerciseIds = widget.previousWorkout!.sets
        .map((s) => s.exerciseId)
        .toSet()
        .toList();
    for (var exId in uniqueExerciseIds) {
      var historySets = widget.previousWorkout!.sets
          .where((s) => s.exerciseId == exId)
          .toList();
      String exerciseName =
          historySets.first.exerciseName ?? 'Unknown Exercise';
      Exercise mockExercise = Exercise(
        id: exId,
        name: exerciseName,
        description: '',
        primaryMuscle: '',
        equipment: '',
        secondaryMuscles: [],
      );

      int savedRest = 90;
      try {
        var routineEx = widget.baseRoutine!.exercises.firstWhere(
          (e) => e.exerciseId == exId,
        );
        if (routineEx.restSeconds > 0) savedRest = routineEx.restSeconds;
      } catch (e) {}

      // Get old notes if they exist (from first set)
      String pastNotes = historySets.first.notes ?? '';

      List<ActiveSet> initialSets = historySets.map((oldSet) {
        return ActiveSet(
          weight: oldSet.weight > 0 ? oldSet.weight : null,
          reps: oldSet.reps > 0 ? oldSet.reps : null,
          isCompleted: false,
        );
      }).toList();

      _activeExercises.add(
        ActiveExercise(
          exercise: mockExercise,
          sets: initialSets,
          restSeconds: savedRest,
          notes: pastNotes,
        ),
      );
    }
  }

  void _initializeFromRoutine() {
    for (var routineEx in widget.baseRoutine!.exercises) {
      Exercise mockExercise = Exercise(
        id: routineEx.exerciseId,
        name: routineEx.exerciseName ?? 'Unknown Exercise',
        description: '',
        primaryMuscle: '',
        equipment: '',
        secondaryMuscles: [],
      );
      int targetSets = routineEx.sets > 0 ? routineEx.sets : 1;
      int targetReps = routineEx.reps > 0 ? routineEx.reps : 10;
      int savedRest = routineEx.restSeconds > 0 ? routineEx.restSeconds : 90;

      List<ActiveSet> initialSets = List.generate(
        targetSets,
        (index) => ActiveSet(reps: targetReps),
      );
      _activeExercises.add(
        ActiveExercise(
          exercise: mockExercise,
          sets: initialSets,
          restSeconds: savedRest,
        ),
      );
    }
  }

  void _initializeFromSelectedExercises() {
    for (var ex in widget.selectedExercises) {
      _activeExercises.add(
        ActiveExercise(exercise: ex, sets: [ActiveSet()], restSeconds: 90),
      );
    }
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _workoutNameController.dispose();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _workoutSecondsElapsed++;
      });
    });
  }

  void _startRestTimer(int restTime) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = restTime;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        _stopRestTimer();
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _adjustRestTime(int seconds) {
    setState(() {
      _restSecondsRemaining += seconds;
      if (_restSecondsRemaining <= 0) {
        _stopRestTimer();
      }
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

  String _formatRestTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      var previousSet = _activeExercises[exerciseIndex].sets.last;
      _activeExercises[exerciseIndex].sets.add(
        ActiveSet(weight: previousSet.weight, reps: previousSet.reps),
      );
    });
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex) {
    setState(() {
      bool wasCompleted =
          _activeExercises[exerciseIndex].sets[setIndex].isCompleted;
      _activeExercises[exerciseIndex].sets[setIndex].isCompleted =
          !wasCompleted;

      if (!wasCompleted) {
        _startRestTimer(_activeExercises[exerciseIndex].restSeconds);
      }
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
            SnackBar(
              content: Text(
                '${selectedExercise.name} is already in the workout.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      setState(() {
        _activeExercises.add(
          ActiveExercise(
            exercise: selectedExercise,
            sets: [ActiveSet()],
            restSeconds: 90,
          ),
        );
      });
    }
  }

  Future<void> _showRestTimerPicker(int exerciseIndex) async {
    int currentRest = _activeExercises[exerciseIndex].restSeconds;
    int selectedMinutes = currentRest ~/ 60;
    int selectedSeconds = currentRest % 60;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Set Rest Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select rest duration for this exercise',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'MIN',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<int>(
                            dropdownColor: const Color(0xFF2C2C2C),
                            value: selectedMinutes,
                            items: List.generate(
                              11,
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text(
                                  '$i',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (val) =>
                                setDialogState(() => selectedMinutes = val!),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        ':',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          const Text(
                            'SEC',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<int>(
                            dropdownColor: const Color(0xFF2C2C2C),
                            value: selectedSeconds,
                            items: [0, 15, 30, 45]
                                .map(
                                  (i) => DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                      i.toString().padLeft(2, '0'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedSeconds = val!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _activeExercises[exerciseIndex].restSeconds =
                          (selectedMinutes * 60) + selectedSeconds;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to write a note for an exercise
  Future<void> _showNotesDialog(int exerciseIndex) async {
    TextEditingController noteController = TextEditingController(
      text: _activeExercises[exerciseIndex].notes,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Notes - ${_activeExercises[exerciseIndex].exercise.name}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a note about this exercise...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {
                setState(() {
                  _activeExercises[exerciseIndex].notes = noteController.text
                      .trim();
                });
                Navigator.pop(context);
              },
              child: const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _askToCancelWorkout() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Cancel Workout?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Are you sure you want to cancel this workout? All progress will be lost.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'NO, RESUME',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    'CANCEL WORKOUT',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _askToFinishWorkout() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Finish Workout?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Are you ready to complete and save this workout?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'NOT YET',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text(
                    'FINISH',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _attemptFinishWorkout() async {
    FocusScope.of(context).unfocus();

    if (_activeExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final List<WorkoutSet> setsToSend = [];
    int exerciseOrder = 1;

    for (var activeEx in _activeExercises) {
      bool hasAtLeastOneValidSet = false;
      int setNumber = 1;

      for (var s in activeEx.sets) {
        if (s.isCompleted && s.weight != null && s.reps != null) {
          hasAtLeastOneValidSet = true;
          setsToSend.add(
            WorkoutSet(
              exerciseId: activeEx.exercise.id,
              exerciseName: activeEx.exercise.name,
              exerciseOrder: exerciseOrder,
              setNumber: setNumber,
              weight: s.weight!,
              reps: s.reps!,
              timestamp: DateTime.now(),
              notes: setNumber == 1
                  ? activeEx.notes
                  : null, // Save note in first set to travel to DB
            ),
          );
          setNumber++;
        }
      }

      if (!hasAtLeastOneValidSet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You left "${activeEx.exercise.name}" empty. Please complete at least one set or remove the exercise.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      exerciseOrder++;
    }

    bool shouldFinish = await _askToFinishWorkout();
    if (!shouldFinish) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final int realUserId = prefs.getInt('user_id') ?? 1;
      String finalName = _workoutNameController.text.trim();
      if (finalName.isEmpty) finalName = "Today's Workout";

      final DateTime realStartTime = DateTime.now().subtract(
        Duration(seconds: _workoutSecondsElapsed),
      );
      final DateTime endTime = DateTime.now();

      final workout = Workout(
        name: finalName,
        startTime: realStartTime,
        endTime: endTime,
        userId: realUserId,
        routineId: widget.baseRoutine?.id,
        sets: setsToSend,
      );

      final workoutSuccess = await _saveWorkoutUseCase(workout);

      setState(() {
        _isSaving = false;
      });

      if (workoutSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save workout.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on AuthenticationFailure catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on NetworkFailure catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _attemptFinishWorkout,
            ),
          ),
        );
      }
    } on ValidationFailure catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool cancel = await _askToCancelWorkout();
        return cancel;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              bool cancel = await _askToCancelWorkout();
              if (cancel && mounted) Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Workout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatTime(_workoutSecondsElapsed),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          actions: [
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _attemptFinishWorkout,
                    child: const Text(
                      'FINISH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),

        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: const Color(0xFF1A1A1A),
                  child: TextField(
                    controller: _workoutNameController,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Workout Name',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _activeExercises.removeAt(oldIndex);
                        _activeExercises.insert(newIndex, item);
                      });
                    },
                    footer: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToAddExercise,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Add Exercise',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Notes button
                                  IconButton(
                                    icon: Icon(
                                      Icons.notes,
                                      color: activeEx.notes.isNotEmpty
                                          ? Colors.amber
                                          : Colors
                                                .grey, // If note is written, shine in gold
                                    ),
                                    onPressed: () =>
                                        _showNotesDialog(exerciseIndex),
                                  ),

                                  // Rest button
                                  InkWell(
                                    onTap: () =>
                                        _showRestTimerPicker(exerciseIndex),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.timer,
                                            color: Colors.blueAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatRestTime(
                                              activeEx.restSeconds,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Button to remove exercise
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _activeExercises.removeAt(
                                          exerciseIndex,
                                        );
                                      });
                                    },
                                  ),

                                  ReorderableDragStartListener(
                                    index: exerciseIndex,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Colors.grey,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // If there's a saved note, show it below the exercise title
                              if (activeEx.notes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.amber.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      activeEx.notes,
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      'SET',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'KG',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'REPS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.grey),
                              ...List.generate(activeEx.sets.length, (
                                setIndex,
                              ) {
                                final currentSet = activeEx.sets[setIndex];

                                String weightStr = '';
                                if (currentSet.weight != null &&
                                    currentSet.weight! > 0) {
                                  weightStr =
                                      currentSet.weight! ==
                                          currentSet.weight!.toInt()
                                      ? currentSet.weight!.toInt().toString()
                                      : currentSet.weight!.toString();
                                }

                                String repsStr =
                                    (currentSet.reps != null &&
                                        currentSet.reps! > 0)
                                    ? currentSet.reps!.toString()
                                    : '';

                                return Dismissible(
                                  key: Key(currentSet.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.8,
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    setState(() {
                                      activeEx.sets.removeAt(setIndex);
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[850],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${setIndex + 1}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                                              fillColor: currentSet.isCompleted
                                                  ? Colors.green.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : const Color(0xFF2C2C2C),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              hintText: '-',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                            onChanged: (value) =>
                                                currentSet.weight =
                                                    double.tryParse(value),
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
                                              fillColor: currentSet.isCompleted
                                                  ? Colors.green.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : const Color(0xFF2C2C2C),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              hintText: '-',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                            onChanged: (value) =>
                                                currentSet.reps = int.tryParse(
                                                  value,
                                                ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.check_circle,
                                              color: currentSet.isCompleted
                                                  ? Colors.green
                                                  : Colors.grey[700],
                                              size: 28,
                                            ),
                                            onPressed: () {
                                              FocusScope.of(context).unfocus();
                                              _toggleSetCompletion(
                                                exerciseIndex,
                                                setIndex,
                                              );
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
                                  onPressed: () =>
                                      _addSetToExercise(exerciseIndex),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Add Set',
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blueAccent
                                        .withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isResting)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blueAccent.withValues(alpha: 0.95),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 30),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white,
                          ),
                          onPressed: () => _adjustRestTime(-30),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'REST',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatRestTime(_restSecondsRemaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                          ),
                          onPressed: () => _adjustRestTime(30),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _stopRestTimer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

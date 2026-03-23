// lib/features/workouts/presentation/screens/active_workout_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/core_dependencies.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/routine.dart';
import '../../domain/use_cases/save_workout.dart';
import '../../workout_dependencies.dart';
import 'exercise_selection_screen.dart';

// ── Local state models ────────────────────────────────────────────────────────

class ActiveSet {
  final String id;
  double? weight;
  int? reps;
  bool isCompleted;
  bool isWarmup;

  ActiveSet({
    this.weight,
    this.reps,
    this.isCompleted = false,
    this.isWarmup = false,
  }) : id = UniqueKey().toString();
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

// ── Screen ────────────────────────────────────────────────────────────────────

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
  late final TextEditingController _workoutNameController;

  bool _isSaving = false;
  Timer? _workoutTimer;
  int _workoutSecondsElapsed = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _saveWorkoutUseCase = WorkoutDependencies.saveWorkoutUseCase;
    _workoutNameController = TextEditingController(
      text: widget.baseRoutine?.name ?? "Today's Workout",
    );

    if (widget.previousWorkout != null && widget.baseRoutine != null) {
      _initializeFromPreviousWorkout();
    } else if (widget.baseRoutine != null) {
      _initializeFromRoutine();
    } else {
      _initializeFromSelectedExercises();
    }

    _startWorkoutTimer();
  }

  // ── Initialization ────────────────────────────────────────────────────────

  void _initializeFromPreviousWorkout() {
    final uniqueIds = widget.previousWorkout!.sets
        .map((s) => s.exerciseId)
        .toSet()
        .toList();

    for (final exId in uniqueIds) {
      final historySets = widget.previousWorkout!.sets
          .where((s) => s.exerciseId == exId)
          .toList();

      final name = historySets.first.exerciseName ?? 'Unknown Exercise';
      final mock = Exercise(
        id: exId,
        name: name,
        description: '',
        primaryMuscle: '',
        category: '',
        secondaryMuscles: [],
      );

      int savedRest = 90;
      try {
        final re = widget.baseRoutine!.exercises.firstWhere(
          (e) => e.exerciseId == exId,
        );
        if (re.restSeconds > 0) savedRest = re.restSeconds;
      } catch (_) {}

      final pastNotes = historySets.first.notes ?? '';
      final sets = historySets.map((s) {
        return ActiveSet(
          weight: s.weight > 0 ? s.weight : null,
          reps: s.reps > 0 ? s.reps : null,
          isWarmup: s.isWarmup,
        );
      }).toList();

      _activeExercises.add(
        ActiveExercise(
          exercise: mock,
          sets: sets,
          restSeconds: savedRest,
          notes: pastNotes,
        ),
      );
    }
  }

  void _initializeFromRoutine() {
    for (final re in widget.baseRoutine!.exercises) {
      final mock = Exercise(
        id: re.exerciseId,
        name: re.exerciseName ?? 'Unknown Exercise',
        description: '',
        primaryMuscle: '',
        category: '',
        secondaryMuscles: [],
      );
      final targetSets = re.sets > 0 ? re.sets : 1;
      final targetReps = re.reps > 0 ? re.reps : 10;
      final savedRest = re.restSeconds > 0 ? re.restSeconds : 90;

      // Pre-fill with targetWeight from routine definition if available
      _activeExercises.add(
        ActiveExercise(
          exercise: mock,
          sets: List.generate(
            targetSets,
            (_) => ActiveSet(reps: targetReps, weight: re.targetWeight),
          ),
          restSeconds: savedRest,
        ),
      );
    }
  }

  void _initializeFromSelectedExercises() {
    for (final ex in widget.selectedExercises) {
      _activeExercises.add(
        ActiveExercise(exercise: ex, sets: [ActiveSet()], restSeconds: 90),
      );
    }
  }

  // ── Timers ────────────────────────────────────────────────────────────────

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _workoutSecondsElapsed++);
    });
  }

  void _startRestTimer(int restTime) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = restTime;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
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
      if (_restSecondsRemaining <= 0) _stopRestTimer();
    });
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _workoutNameController.dispose();
    super.dispose();
  }

  // ── Set interactions ──────────────────────────────────────────────────────

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      final prev = _activeExercises[exerciseIndex].sets.last;
      _activeExercises[exerciseIndex].sets.add(
        ActiveSet(weight: prev.weight, reps: prev.reps),
      );
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _activeExercises[exerciseIndex].sets.removeAt(setIndex);
    });
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex) {
    setState(() {
      final s = _activeExercises[exerciseIndex].sets[setIndex];
      s.isCompleted = !s.isCompleted;
      if (s.isCompleted) {
        _startRestTimer(_activeExercises[exerciseIndex].restSeconds);
      }
    });
  }

  /// Shows a small bottom sheet to toggle warmup for the tapped set.
  void _showSetOptions(int exerciseIndex, int setIndex) {
    final set = _activeExercises[exerciseIndex].sets[setIndex];
    final isWarmup = set.isWarmup;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Set ${setIndex + 1} options',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF2A2A2A)),

                // Warmup toggle
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isWarmup
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: isWarmup ? Colors.orange : const Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isWarmup ? 'Remove warmup' : 'Mark as warmup',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  subtitle: Text(
                    isWarmup
                        ? 'This set will count towards your volume'
                        : 'Warmup sets are excluded from volume tracking',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    setState(() => set.isWarmup = !set.isWarmup);
                    Navigator.pop(context);
                  },
                ),

                // Delete set
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete set',
                    style: TextStyle(color: Colors.redAccent, fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeSet(exerciseIndex, setIndex);
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  Future<void> _navigateToAddExercise() async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );
    if (selected == null) return;

    if (_activeExercises.any((e) => e.exercise.id == selected.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected.name} is already in the workout.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _activeExercises.add(
        ActiveExercise(
          exercise: selected,
          sets: [ActiveSet()],
          restSeconds: 90,
        ),
      );
    });
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool> _askToCancelWorkout() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmDialog(
            title: 'Cancel Workout?',
            subtitle: 'All progress will be lost.',
            confirmLabel: 'Cancel workout',
            confirmColor: Colors.redAccent,
          ),
        ) ??
        false;
  }

  Future<bool> _askToFinishWorkout() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => const _ConfirmDialog(
            title: 'Finish Workout?',
            subtitle: 'Ready to save and complete this session?',
            confirmLabel: "Let's go",
            confirmColor: Colors.blueAccent,
          ),
        ) ??
        false;
  }

  Future<void> _showRestTimerPicker(int exerciseIndex) async {
    int selMin = _activeExercises[exerciseIndex].restSeconds ~/ 60;
    int selSec = _activeExercises[exerciseIndex].restSeconds % 60;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
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
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RestDropdown(
                  label: 'MIN',
                  value: selMin,
                  items: List.generate(11, (i) => i),
                  onChanged: (v) => setDialogState(() => selMin = v!),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _RestDropdown(
                  label: 'SEC',
                  value: selSec,
                  items: [0, 15, 30, 45],
                  onChanged: (v) => setDialogState(() => selSec = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
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
                        selMin * 60 + selSec;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showNotesDialog(int exerciseIndex) async {
    final ctrl = TextEditingController(
      text: _activeExercises[exerciseIndex].notes,
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Notes — ${_activeExercises[exerciseIndex].exercise.name}',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Add a note...',
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
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              setState(() {
                _activeExercises[exerciseIndex].notes = ctrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Finish workout ────────────────────────────────────────────────────────

  Future<void> _attemptFinishWorkout() async {
    FocusScope.of(context).unfocus();

    if (_activeExercises.isEmpty) {
      _showError('Please add at least one exercise.');
      return;
    }

    final setsToSend = <WorkoutSet>[];
    int exerciseOrder = 1;

    for (final activeEx in _activeExercises) {
      int setNumber = 1;
      bool hasValidSet = false;

      for (final s in activeEx.sets) {
        if (s.isCompleted && s.weight != null && s.reps != null) {
          hasValidSet = true;
          setsToSend.add(
            WorkoutSet(
              exerciseId: activeEx.exercise.id,
              exerciseName: activeEx.exercise.name,
              exerciseOrder: exerciseOrder,
              setNumber: setNumber,
              weight: s.weight!,
              reps: s.reps!,
              timestamp: DateTime.now(),
              notes: setNumber == 1 ? activeEx.notes : null,
              isWarmup: s.isWarmup,
              isCompleted: true,
            ),
          );
          setNumber++;
        }
      }

      if (!hasValidSet) {
        _showError(
          '"${activeEx.exercise.name}" has no completed sets. '
          'Complete at least one or remove the exercise.',
        );
        return;
      }
      exerciseOrder++;
    }

    final confirmed = await _askToFinishWorkout();
    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final userId = await CoreDependencies.sessionService.getUserId();
      if (userId == null || userId <= 0) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      }

      final finalName = _workoutNameController.text.trim().isEmpty
          ? "Today's Workout"
          : _workoutNameController.text.trim();

      final workout = Workout(
        name: finalName,
        startTime: DateTime.now().subtract(
          Duration(seconds: _workoutSecondsElapsed),
        ),
        endTime: DateTime.now(),
        userId: userId,
        routineId: widget.baseRoutine?.id,
        sets: setsToSend,
      );

      await _saveWorkoutUseCase(workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on AuthenticationFailure catch (e) {
      _showError(e.message);
    } on NetworkFailure catch (e) {
      _showError(e.message, retryable: true);
    } on ValidationFailure catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not save: ${e.toString()}', retryable: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message, {bool retryable = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: retryable ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 4),
        action: retryable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _attemptFinishWorkout,
              )
            : null,
      ),
    );
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  String _formatTime(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    final hStr = h > 0 ? '${h.toString().padLeft(2, '0')}:' : '';
    return '$hStr${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatRestTime(int secs) {
    return '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _askToCancelWorkout(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              if (await _askToCancelWorkout() && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Workout',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatTime(_workoutSecondsElapsed),
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: Colors.blueAccent,
          actions: [
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
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
                        fontSize: 15,
                      ),
                    ),
                  ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Workout name field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xFF1A1A1A),
                  child: TextField(
                    controller: _workoutNameController,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Workout Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _activeExercises.removeAt(oldIndex);
                        _activeExercises.insert(newIndex, item);
                      });
                    },
                    footer: Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: _navigateToAddExercise,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Exercise'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          side: const BorderSide(
                            color: Colors.blueAccent,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    itemCount: _activeExercises.length,
                    itemBuilder: (context, exerciseIndex) {
                      final activeEx = _activeExercises[exerciseIndex];
                      return _ExerciseCard(
                        key: Key(activeEx.id),
                        activeEx: activeEx,
                        exerciseIndex: exerciseIndex,
                        onRemoveExercise: () => setState(
                          () => _activeExercises.removeAt(exerciseIndex),
                        ),
                        onNotes: () => _showNotesDialog(exerciseIndex),
                        onRestTimer: () => _showRestTimerPicker(exerciseIndex),
                        onAddSet: () => _addSetToExercise(exerciseIndex),
                        onToggleComplete: (setIndex) =>
                            _toggleSetCompletion(exerciseIndex, setIndex),
                        onSetOptions: (setIndex) =>
                            _showSetOptions(exerciseIndex, setIndex),
                        formatRestTime: _formatRestTime,
                        dragHandle: ReorderableDragStartListener(
                          index: exerciseIndex,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: Color(0xFF555555),
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Rest timer overlay
            if (_isResting)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _RestTimerBanner(
                  secondsRemaining: _restSecondsRemaining,
                  formatRestTime: _formatRestTime,
                  onAdjust: _adjustRestTime,
                  onSkip: _stopRestTimer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ActiveExercise activeEx;
  final int exerciseIndex;
  final VoidCallback onRemoveExercise;
  final VoidCallback onNotes;
  final VoidCallback onRestTimer;
  final VoidCallback onAddSet;
  final ValueChanged<int> onToggleComplete;
  final ValueChanged<int> onSetOptions;
  final String Function(int) formatRestTime;
  final Widget dragHandle;

  const _ExerciseCard({
    super.key,
    required this.activeEx,
    required this.exerciseIndex,
    required this.onRemoveExercise,
    required this.onNotes,
    required this.onRestTimer,
    required this.onAddSet,
    required this.onToggleComplete,
    required this.onSetOptions,
    required this.formatRestTime,
    required this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Exercise header ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    activeEx.exercise.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueAccent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Notes button
                IconButton(
                  icon: Icon(
                    Icons.notes_rounded,
                    color: activeEx.notes.isNotEmpty
                        ? Colors.amber
                        : const Color(0xFF666666),
                    size: 20,
                  ),
                  onPressed: onNotes,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                // Rest timer chip
                GestureDetector(
                  onTap: onRestTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.blueAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          formatRestTime(activeEx.restSeconds),
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
                const SizedBox(width: 2),
                // Remove exercise
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: onRemoveExercise,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                dragHandle,
              ],
            ),

            // Notes preview
            if (activeEx.notes.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  activeEx.notes,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Column headers
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Set number column - same width as the badge below
                  SizedBox(width: 36),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'KG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'REPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Check + (options menu is on set number tap)
                  SizedBox(width: 32),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 6),

            // ── Sets ─────────────────────────────────────────────────────
            ...List.generate(activeEx.sets.length, (setIndex) {
              final s = activeEx.sets[setIndex];
              final weightStr = (s.weight != null && s.weight! > 0)
                  ? (s.weight! == s.weight!.toInt()
                        ? s.weight!.toInt().toString()
                        : s.weight!.toString())
                  : '';
              final repsStr = (s.reps != null && s.reps! > 0)
                  ? s.reps!.toString()
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Set number badge (tap = options) ────────────────
                    GestureDetector(
                      onTap: () => onSetOptions(setIndex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: s.isWarmup
                              ? Colors.orange.withValues(alpha: 0.15)
                              : s.isCompleted
                              ? Colors.green.withValues(alpha: 0.15)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: s.isWarmup
                              ? Border.all(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Center(
                          child: s.isWarmup
                              ? const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.orange,
                                  size: 16,
                                )
                              : Text(
                                  '${setIndex + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: s.isCompleted
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ── Weight field ────────────────────────────────────
                    Expanded(
                      child: TextFormField(
                        initialValue: weightStr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: s.isCompleted
                              ? Colors.green.withValues(alpha: 0.08)
                              : const Color(0xFF252525),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          hintText: '—',
                          hintStyle: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 15,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 9,
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) => s.weight = double.tryParse(v),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ── Reps field ──────────────────────────────────────
                    Expanded(
                      child: TextFormField(
                        initialValue: repsStr,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: s.isCompleted
                              ? Colors.green.withValues(alpha: 0.08)
                              : const Color(0xFF252525),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          hintText: '—',
                          hintStyle: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 15,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 9,
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) => s.reps = int.tryParse(v),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ── Complete button ─────────────────────────────────
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        icon: Icon(
                          Icons.check_circle_rounded,
                          color: s.isCompleted
                              ? Colors.green
                              : const Color(0xFF3A3A3A),
                          size: 26,
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          onToggleComplete(setIndex);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Add set button ───────────────────────────────────────────
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, color: Colors.blueAccent, size: 16),
                label: const Text(
                  'Add Set',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
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

// ── Rest timer banner ─────────────────────────────────────────────────────────

class _RestTimerBanner extends StatelessWidget {
  final int secondsRemaining;
  final String Function(int) formatRestTime;
  final ValueChanged<int> onAdjust;
  final VoidCallback onSkip;

  const _RestTimerBanner({
    required this.secondsRemaining,
    required this.formatRestTime,
    required this.onAdjust,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.blueAccent.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.timer_rounded, color: Colors.white, size: 26),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.white,
              ),
              onPressed: () => onAdjust(-30),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'REST',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  formatRestTime(secondsRemaining),
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
                Icons.add_circle_outline_rounded,
                color: Colors.white,
              ),
              onPressed: () => onAdjust(30),
            ),
            IconButton(
              icon: const Icon(
                Icons.skip_next_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: onSkip,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rest timer dropdown ───────────────────────────────────────────────────────

class _RestDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final ValueChanged<int?> onChanged;

  const _RestDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        DropdownButton<int>(
          dropdownColor: const Color(0xFF2C2C2C),
          value: value,
          items: items.map((i) {
            return DropdownMenuItem(
              value: i,
              child: Text(
                i.toString().padLeft(2, '0'),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Confirm dialog ────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

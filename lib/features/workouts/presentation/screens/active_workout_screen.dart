// lib/features/workouts/presentation/screens/active_workout_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/core_dependencies.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/anatomical_muscle_heatmap.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/routine.dart';
import '../../domain/use_cases/calculate_muscle_heatmap.dart';
import '../../domain/use_cases/evaluate_personal_records.dart';
import '../../domain/use_cases/save_workout.dart';
import '../../domain/use_cases/validate_workout_set.dart';
import '../../workout_dependencies.dart';
import '../services/rest_timer_notification_service.dart';
import '../widgets/exercise_media_viewer.dart';
import 'exercise_selection_screen.dart';
import 'workout_detail_screen.dart';

// ── Local state models ────────────────────────────────────────────────────────

class ActiveSet {
  final String id;
  double? weight;
  int? reps;
  bool isCompleted;
  bool isWarmup;
  PersonalRecordAchievement? prAchievement;

  ActiveSet({
    this.weight,
    this.reps,
    this.isCompleted = false,
    this.isWarmup = false,
    this.prAchievement,
  }) : id = UniqueKey().toString();
}

class ActiveExercise {
  final String id;
  Exercise exercise;
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

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  final List<ActiveExercise> _activeExercises = [];
  late final SaveWorkout _saveWorkoutUseCase;
  late final EvaluatePersonalRecords _evaluatePersonalRecordsUseCase;
  late final TextEditingController _workoutNameController;
  late final RestTimerNotificationService _restNotificationService;
  Map<int, ExerciseHistoricalBest> _historicalBests = {};

  bool _isSaving = false;
  Timer? _workoutTimer;
  int _workoutSecondsElapsed = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 90;
  bool _isResting = false;
  bool _isRestPaused = false;
  bool _restSoundEnabled = true;
  String? _restExerciseName;
  DateTime? _restEndTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enforceImmersiveBottomBar();
    _saveWorkoutUseCase = WorkoutDependencies.saveWorkoutUseCase;
    _evaluatePersonalRecordsUseCase =
        WorkoutDependencies.evaluatePersonalRecordsUseCase;
    _workoutNameController = TextEditingController(
      text: widget.baseRoutine?.name ?? "Today's Workout",
    );
    _restNotificationService = RestTimerNotificationService();
    _restNotificationService.setActionHandler(_handleNotificationAction);

    if (widget.previousWorkout != null) {
      _historicalBests = _evaluatePersonalRecordsUseCase.buildBaselineFromHistory([
        widget.previousWorkout!,
      ]);
    }

    if (widget.previousWorkout != null && widget.baseRoutine != null) {
      _initializeFromPreviousWorkout();
    } else if (widget.baseRoutine != null) {
      _initializeFromRoutine();
    } else {
      _initializeFromSelectedExercises();
    }

    if (widget.baseRoutine != null || widget.previousWorkout != null) {
      _enrichExercisesFromCatalog();
    }
    _loadHistoricalBests();
    _startWorkoutTimer();
  }

  Future<void> _enrichExercisesFromCatalog() async {
    try {
      final catalog = await WorkoutDependencies.getExercisesUseCase();
      if (!mounted || catalog.isEmpty) return;
      final byId = {for (final ex in catalog) ex.id: ex};
      var updated = false;
      for (final activeEx in _activeExercises) {
        final full = byId[activeEx.exercise.id];
        if (full != null) {
          activeEx.exercise = full;
          updated = true;
        }
      }
      if (updated) {
        setState(() {});
      }
    } catch (_) {
      // Mantiene datos básicos de fallback si falla la carga de catálogo.
    }
  }

  Future<void> _loadHistoricalBests() async {
    try {
      final userId = await CoreDependencies.sessionService.getUserId();
      if (userId == null || userId <= 0) return;
      final history = await WorkoutDependencies.getWorkoutHistoryUseCase(userId);
      final baseline =
          _evaluatePersonalRecordsUseCase.buildBaselineFromHistory(history);
      if (!mounted) return;
      setState(() {
        _historicalBests = baseline;
        for (int i = 0; i < _activeExercises.length; i++) {
          _recalculateExercisePrs(i);
        }
      });
    } catch (_) {
      // Si falla la carga de historial remoto, mantenemos la base local previa.
    }
  }

  void _enforceImmersiveBottomBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (View.of(context).viewInsets.bottom == 0) {
        _enforceImmersiveBottomBar();
      }
    });
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isResting &&
        !_isRestPaused &&
        _restEndTime != null) {
      final remaining = _computeRemainingSecondsFromClock();
      if (remaining <= 0) {
        _completeRestTimer();
      } else {
        setState(() => _restSecondsRemaining = remaining);
        _syncRestNotification();
      }
    }
  }

  int _computeRemainingSecondsFromClock() {
    if (_restEndTime == null) return _restSecondsRemaining;
    final remainingMs = _restEndTime!.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _workoutSecondsElapsed++);
    });
  }

  void _startRestTimer(int restTime, {String? exerciseName}) {
    if (restTime <= 0) {
      _stopRestTimer();
      return;
    }
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _isRestPaused = false;
      _restTotalSeconds = restTime;
      _restSecondsRemaining = restTime;
      _restExerciseName = exerciseName;
      _restEndTime = DateTime.now().add(Duration(seconds: restTime));
    });
    _startRestPeriodicTicker();
    _publishRestNotificationWithPermission();
  }

  void _startRestPeriodicTicker() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isResting || _isRestPaused) return;
      final remaining = _computeRemainingSecondsFromClock();
      if (remaining <= 0) {
        _completeRestTimer();
        return;
      }
      if (mounted && remaining != _restSecondsRemaining) {
        setState(() => _restSecondsRemaining = remaining);
      }
    });
  }

  Future<void> _publishRestNotificationWithPermission() async {
    await CoreDependencies.permissionsService.requestRequiredPermissions();
    if (!mounted || !_isResting) return;
    await _syncRestNotification();
  }

  Future<void> _syncRestNotification() async {
    if (!_isResting || _restSecondsRemaining <= 0) return;
    await _restNotificationService.showOrUpdate(
      remainingSeconds: _restSecondsRemaining,
      totalSeconds: _restTotalSeconds,
      isPaused: _isRestPaused,
      soundEnabled: _restSoundEnabled,
      vibrationEnabled: true,
      exerciseName: _restExerciseName,
    );
  }

  void _handleNotificationAction(RestTimerNotificationAction action) {
    if (!mounted || !_isResting) return;
    switch (action) {
      case RestTimerNotificationAction.subtract20:
        _adjustRestTime(-20, haptic: false, syncNative: false);
        break;
      case RestTimerNotificationAction.add20:
        _adjustRestTime(20, haptic: false, syncNative: false);
        break;
      case RestTimerNotificationAction.stop:
        _stopRestTimer(haptic: false, syncNative: false);
        break;
      case RestTimerNotificationAction.completed:
        _completeRestTimer(fromNative: true);
        break;
    }
  }

  void _stopRestTimer({bool haptic = false, bool syncNative = true}) {
    if (haptic) {
      _restNotificationService.lightImpact();
    }
    _restTimer?.cancel();
    _restEndTime = null;
    if (mounted) {
      setState(() {
        _isResting = false;
        _isRestPaused = false;
        _restSecondsRemaining = 0;
      });
    }
    if (syncNative) {
      _restNotificationService.cancel();
    }
  }

  Future<void> _completeRestTimer({bool fromNative = false}) async {
    if (!_isResting) return;
    final playFeedback = !fromNative;
    final soundOn = _restSoundEnabled;
    _stopRestTimer(syncNative: false);
    if (playFeedback) {
      await _restNotificationService.playCompletionFeedback(
        playSound: soundOn,
        vibrate: true,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Descanso finalizado · ¡A por la siguiente serie!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blueAccent,
        ),
      );
  }

  void _toggleRestPause() {
    if (!_isResting) return;
    _restNotificationService.lightImpact();
    setState(() {
      if (_isRestPaused) {
        _isRestPaused = false;
        _restEndTime = DateTime.now().add(Duration(seconds: _restSecondsRemaining));
        _startRestPeriodicTicker();
      } else {
        _restSecondsRemaining = _computeRemainingSecondsFromClock();
        _isRestPaused = true;
        _restEndTime = null;
        _restTimer?.cancel();
      }
    });
    _syncRestNotification();
  }

  void _toggleRestSound() {
    _restNotificationService.lightImpact();
    setState(() => _restSoundEnabled = !_restSoundEnabled);
    _syncRestNotification();
  }

  void _adjustRestTime(
    int seconds, {
    bool haptic = true,
    bool syncNative = true,
  }) {
    if (!_isResting) return;
    if (haptic) {
      _restNotificationService.lightImpact();
    }
    final current = _isRestPaused
        ? _restSecondsRemaining
        : _computeRemainingSecondsFromClock();
    final updated = current + seconds;
    if (updated <= 0) {
      _stopRestTimer(syncNative: syncNative);
      return;
    }
    setState(() {
      _restSecondsRemaining = updated;
      if (updated > _restTotalSeconds) {
        _restTotalSeconds = updated;
      }
      if (!_isRestPaused) {
        _restEndTime = DateTime.now().add(Duration(seconds: updated));
      }
    });
    if (syncNative) {
      _syncRestNotification();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restNotificationService.setActionHandler(null);
    _restNotificationService.cancel();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _workoutNameController.dispose();
    super.dispose();
  }

  // ── Set interactions ──────────────────────────────────────────────────────

  void _recalculateExercisePrs(int exerciseIndex) {
    final activeEx = _activeExercises[exerciseIndex];
    final inputs = List<EvaluableSetInput>.generate(
      activeEx.sets.length,
      (i) => (
        setIndex: i,
        weight: activeEx.sets[i].weight,
        reps: activeEx.sets[i].reps,
        isCompleted: activeEx.sets[i].isCompleted,
        isWarmup: activeEx.sets[i].isWarmup,
      ),
    );
    final prMap = _evaluatePersonalRecordsUseCase.evaluateExerciseSets(
      exerciseId: activeEx.exercise.id,
      exerciseName: activeEx.exercise.name,
      sets: inputs,
      historicalBest: _historicalBests[activeEx.exercise.id],
    );
    for (int i = 0; i < activeEx.sets.length; i++) {
      activeEx.sets[i].prAchievement = prMap[i];
    }
  }

  void _handleSetValuesChanged(int exerciseIndex, int setIndex) {
    final activeEx = _activeExercises[exerciseIndex];
    final s = activeEx.sets[setIndex];
    if (s.isCompleted) {
      final invalidReason = WorkoutSetValidator.validateForCompletion(
        weight: s.weight,
        reps: s.reps,
        exercise: activeEx.exercise,
      );
      setState(() {
        if (invalidReason != null) {
          s.isCompleted = false;
        }
        _recalculateExercisePrs(exerciseIndex);
      });
      return;
    }
    setState(() {});
  }

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
      _recalculateExercisePrs(exerciseIndex);
    });
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex) {
    final activeExercise = _activeExercises[exerciseIndex];
    final s = activeExercise.sets[setIndex];

    if (!s.isCompleted) {
      final validationError = WorkoutSetValidator.validateForCompletion(
        weight: s.weight,
        reps: s.reps,
        exercise: activeExercise.exercise,
      );
      if (validationError != null) {
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  validationError,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.amber,
                duration: const Duration(seconds: 3),
              ),
            );
        }
        return;
      }
    }

    setState(() {
      s.isCompleted = !s.isCompleted;
      _recalculateExercisePrs(exerciseIndex);
    });
    if (s.isCompleted) {
      if (s.prAchievement != null && mounted) {
        final pr = s.prAchievement!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '🏆 ¡Nuevo PR en ${pr.exerciseName}! ${pr.improvementLabel}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 3),
            ),
          );
      }
      _startRestTimer(
        activeExercise.restSeconds,
        exerciseName: activeExercise.exercise.name,
      );
    }
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
                    setState(() {
                      set.isWarmup = !set.isWarmup;
                      _recalculateExercisePrs(exerciseIndex);
                    });
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
                  value: const [0, 10, 15, 20, 30, 40, 45, 50].contains(selSec)
                      ? selSec
                      : (selSec ~/ 10) * 10,
                  items: const [0, 10, 15, 20, 30, 40, 45, 50],
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
        final isValid = WorkoutSetValidator.validateForCompletion(
              weight: s.weight,
              reps: s.reps,
              exercise: activeEx.exercise,
            ) ==
            null;
        if (s.isCompleted && isValid) {
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

    final tempWorkout = Workout(
      id: 0,
      userId: 0, // Mock
      routineId: widget.baseRoutine?.id,
      name: _workoutNameController.text.trim().isEmpty
          ? "Today's Workout"
          : _workoutNameController.text.trim(),
      startTime: DateTime.now().subtract(Duration(seconds: _workoutSecondsElapsed)),
      endTime: DateTime.now(),
      sets: setsToSend,
    );

    final personalRecords = _evaluatePersonalRecordsUseCase.evaluateWorkout(
      tempWorkout,
      _historicalBests,
    );

    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(
          workout: tempWorkout,
          isPreview: true,
          personalRecords: personalRecords,
        ),
      ),
    ) ?? false;

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
      WorkoutDependencies.notifyWorkoutSaved();

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

  // ── Live Muscle Heatmap ───────────────────────────────────────────────────

  void _showLiveMuscleHeatmapSheet() {
    FocusScope.of(context).unfocus();
    final exercisesById = <int, Exercise>{
      for (final activeEx in _activeExercises) activeEx.exercise.id: activeEx.exercise,
    };

    final hasCompletedSets = _activeExercises.any(
      (ex) => ex.sets.any((s) => !s.isWarmup && s.isCompleted),
    );

    final sets = <WorkoutSet>[];
    int exerciseOrder = 1;
    for (final activeEx in _activeExercises) {
      int setNumber = 1;
      for (final s in activeEx.sets) {
        if (s.isWarmup) continue;
        if (hasCompletedSets && !s.isCompleted) continue;
        sets.add(
          WorkoutSet(
            exerciseId: activeEx.exercise.id,
            exerciseName: activeEx.exercise.name,
            exerciseOrder: exerciseOrder,
            setNumber: setNumber,
            weight: s.weight ?? 0,
            reps: s.reps ?? 0,
            timestamp: DateTime.now(),
            isWarmup: false,
            isCompleted: s.isCompleted,
          ),
        );
        setNumber++;
      }
      exerciseOrder++;
    }

    final tempWorkout = Workout(
      id: 0,
      userId: 0,
      name: _workoutNameController.text.trim().isEmpty
          ? 'Entrenamiento actual'
          : _workoutNameController.text.trim(),
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      sets: sets,
    );

    final liveData = const CalculateMuscleHeatmap()(
      workouts: [tempWorkout],
      exercisesById: exercisesById,
      includeIncompleteSets: !hasCompletedSets,
    );

    final String subtitle;
    if (sets.isEmpty) {
      subtitle =
          'Añade series o ejercicios para visualizar los músculos trabajados';
    } else if (hasCompletedSets) {
      subtitle =
          'Basado en ${sets.length} ${sets.length == 1 ? 'serie completada' : 'series completadas'}';
    } else {
      subtitle =
          'Vista previa según ${sets.length} ${sets.length == 1 ? 'serie planificada' : 'series planificadas'}';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Mapa muscular en vivo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnatomicalMuscleHeatmap(
                    singleData: liveData,
                    subtitle: subtitle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _askToCancelWorkout();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              if (await _askToCancelWorkout() && context.mounted) {
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
            IconButton(
              icon: const Icon(
                Icons.accessibility_new_rounded,
                color: Colors.white,
              ),
              tooltip: 'Mapa muscular en vivo',
              onPressed: _showLiveMuscleHeatmapSheet,
            ),
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
        body: SafeArea(
          child: Stack(
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                          historicalBest:
                              _historicalBests[activeEx.exercise.id],
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
                          onSetValuesChanged: (setIndex) =>
                              _handleSetValuesChanged(exerciseIndex, setIndex),
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
                    totalSeconds: _restTotalSeconds,
                    isPaused: _isRestPaused,
                    soundEnabled: _restSoundEnabled,
                    formatRestTime: _formatRestTime,
                    onAdjust: _adjustRestTime,
                    onTogglePause: _toggleRestPause,
                    onToggleSound: _toggleRestSound,
                    onSkip: () => _stopRestTimer(haptic: true),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ActiveExercise activeEx;
  final int exerciseIndex;
  final ExerciseHistoricalBest? historicalBest;
  final VoidCallback onRemoveExercise;
  final VoidCallback onNotes;
  final VoidCallback onRestTimer;
  final VoidCallback onAddSet;
  final ValueChanged<int> onToggleComplete;
  final ValueChanged<int> onSetOptions;
  final ValueChanged<int> onSetValuesChanged;
  final String Function(int) formatRestTime;
  final Widget dragHandle;

  const _ExerciseCard({
    super.key,
    required this.activeEx,
    required this.exerciseIndex,
    this.historicalBest,
    required this.onRemoveExercise,
    required this.onNotes,
    required this.onRestTimer,
    required this.onAddSet,
    required this.onToggleComplete,
    required this.onSetOptions,
    required this.onSetValuesChanged,
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
                ExerciseThumbnail(
                  exercise: activeEx.exercise,
                  size: 38,
                  onTap: () => showExerciseDetailSheet(
                    context,
                    activeEx.exercise,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => showExerciseDetailSheet(
                      context,
                      activeEx.exercise,
                    ),
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

            if (historicalBest != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Mejor histórica: ${historicalBest!.formatSummary()}',
                        style: TextStyle(
                          color: Colors.amber.shade200.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
              final pr = s.prAchievement;
              final isBodyweight = WorkoutSetValidator.isBodyweightExercise(
                activeEx.exercise,
              );
              final weightStr = s.weight != null &&
                      (s.weight! > 0 || (isBodyweight && s.weight == 0))
                  ? ExerciseHistoricalBest.formatWeight(s.weight!)
                  : '';
              final repsStr = (s.reps != null && s.reps! > 0)
                  ? s.reps!.toString()
                  : '';
              final canComplete = WorkoutSetValidator.validateForCompletion(
                    weight: s.weight,
                    reps: s.reps,
                    exercise: activeEx.exercise,
                  ) ==
                  null;

              return Container(
                key: ValueKey(s.id),
                margin: const EdgeInsets.only(bottom: 6),
                padding: pr != null
                    ? const EdgeInsets.fromLTRB(6, 6, 6, 6)
                    : EdgeInsets.zero,
                decoration: pr != null
                    ? BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
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
                            onChanged: (v) {
                              s.weight = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              onSetValuesChanged(setIndex);
                            },
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
                            onChanged: (v) {
                              s.reps = int.tryParse(v.trim());
                              onSetValuesChanged(setIndex);
                            },
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
                                  : canComplete
                                  ? const Color(0xFF5A5A5A)
                                  : const Color(0xFF2D2D2D),
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
                    if (pr != null) ...[
                      const SizedBox(height: 6),
                      _AnimatedPrBadge(achievement: pr),
                    ],
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

class _AnimatedPrBadge extends StatelessWidget {
  final PersonalRecordAchievement achievement;

  const _AnimatedPrBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.25),
              Colors.orange.withValues(alpha: 0.14),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              achievement.badgeLabel,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                achievement.improvementLabel,
                style: TextStyle(
                  color: Colors.amber.shade100,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
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
  final int totalSeconds;
  final bool isPaused;
  final bool soundEnabled;
  final String Function(int) formatRestTime;
  final ValueChanged<int> onAdjust;
  final VoidCallback onTogglePause;
  final VoidCallback onToggleSound;
  final VoidCallback onSkip;

  const _RestTimerBanner({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.isPaused,
    required this.soundEnabled,
    required this.formatRestTime,
    required this.onAdjust,
    required this.onTogglePause,
    required this.onToggleSound,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSeconds > 0 ? totalSeconds : 1;
    final progress = (secondsRemaining / safeTotal).clamp(0.0, 1.0);

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      color: const Color(0xFF1A2A44),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.blueAccent.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaused ? Colors.amberAccent : Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPaused
                            ? Icons.play_circle_outline_rounded
                            : Icons.pause_circle_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: isPaused ? 'Reanudar' : 'Pausar',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onTogglePause,
                    ),
                    IconButton(
                      icon: Icon(
                        soundEnabled
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: soundEnabled ? Colors.white : Colors.white54,
                        size: 22,
                      ),
                      tooltip: soundEnabled
                          ? 'Silenciar alerta sonora'
                          : 'Activar alerta sonora',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onToggleSound,
                    ),
                  ],
                ),
                _RestStepButton(
                  label: '-20s',
                  onPressed: () => onAdjust(-20),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPaused ? 'PAUSADO' : 'DESCANSO',
                      style: TextStyle(
                        color: isPaused ? Colors.amberAccent : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      formatRestTime(secondsRemaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                _RestStepButton(
                  label: '+20s',
                  onPressed: () => onAdjust(20),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  tooltip: 'Terminar descanso',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onSkip,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestStepButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RestStepButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.blueAccent.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
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

// lib/features/workouts/presentation/screens/edit_routine_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/workout.dart';
import '../../workout_dependencies.dart';
import 'exercise_selection_screen.dart';

// ── Local state models ────────────────────────────────────────────────────────

class _DraftSet {
  final String id;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  bool isWarmup;

  _DraftSet({double? weight, int? reps, this.isWarmup = false})
    : id = UniqueKey().toString(),
      weightCtrl = TextEditingController(text: _fmtWeight(weight)),
      repsCtrl = TextEditingController(
        text: reps != null && reps > 0 ? reps.toString() : '',
      );

  static String _fmtWeight(double? w) {
    if (w == null || w <= 0) return '';
    return w == w.toInt() ? w.toInt().toString() : w.toString();
  }

  double? get weight => double.tryParse(weightCtrl.text);
  int? get reps => int.tryParse(repsCtrl.text);

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

class _DraftExercise {
  final String widgetKey;
  final int? routineExerciseId;
  final Exercise exercise;
  final List<_DraftSet> sets;
  final TextEditingController restCtrl;

  _DraftExercise({
    required this.exercise,
    this.routineExerciseId,
    required List<_DraftSet> sets,
    int restSeconds = 90,
  }) : widgetKey = UniqueKey().toString(),
       sets = sets,
       restCtrl = TextEditingController(text: restSeconds.toString());

  int get restSeconds => int.tryParse(restCtrl.text) ?? 90;

  void dispose() {
    restCtrl.dispose();
    for (final s in sets) {
      s.dispose();
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class EditRoutineScreen extends StatefulWidget {
  final Routine routine;

  /// Último workout completado con esta rutina.
  /// Si no es null, sus pesos/reps/isWarmup se usan para pre-poblar cada set.
  final Workout? lastWorkout;

  const EditRoutineScreen({super.key, required this.routine, this.lastWorkout});

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final List<_DraftExercise> _exercises;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descController = TextEditingController(
      text: widget.routine.description ?? '',
    );
    _exercises = _buildDraftExercises();
  }

  /// Construye los borradores de ejercicios.
  ///
  /// Fuente de datos por prioridad:
  /// 1. [lastWorkout] — pesos/reps/isWarmup reales de la última sesión, por set.
  /// 2. [RoutineExercise.targetWeight] / [RoutineExercise.reps] — valores target.
  /// 3. Vacío — primer uso sin historial.
  List<_DraftExercise> _buildDraftExercises() {
    return widget.routine.exercises.map((re) {
      // Buscar los WorkoutSets del último entrenamiento para este ejercicio,
      // ordenados por setNumber para mantener el orden correcto.
      final lastSets =
          widget.lastWorkout?.sets
              .where((s) => s.exerciseId == re.exerciseId)
              .toList()
            ?..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      List<_DraftSet> draftSets;

      if (lastSets != null && lastSets.isNotEmpty) {
        // Pre-poblar desde el último workout real (incluyendo isWarmup)
        draftSets = lastSets.map((s) {
          return _DraftSet(
            weight: s.weight > 0 ? s.weight : null,
            reps: s.reps > 0 ? s.reps : null,
            isWarmup: s.isWarmup,
          );
        }).toList();
      } else {
        // Sin historial: usar targetWeight/reps de la definición de la rutina
        final count = re.sets > 0 ? re.sets : 1;
        draftSets = List.generate(
          count,
          (_) => _DraftSet(
            weight: re.targetWeight,
            reps: re.reps > 0 ? re.reps : null,
          ),
        );
      }

      return _DraftExercise(
        routineExerciseId: re.id,
        exercise: Exercise(
          id: re.exerciseId,
          name: re.exerciseName ?? '',
          description: '',
          primaryMuscle: '',
          category: '',
          secondaryMuscles: [],
        ),
        sets: draftSets,
        restSeconds: re.restSeconds,
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  // ── Set interactions ──────────────────────────────────────────────────────

  void _addSet(int exIndex) {
    setState(() {
      final prev = _exercises[exIndex].sets.last;
      _exercises[exIndex].sets.add(
        _DraftSet(weight: prev.weight, reps: prev.reps),
      );
    });
  }

  void _removeSet(int exIndex, int setIndex) {
    if (_exercises[exIndex].sets.length <= 1) {
      _snack('An exercise must have at least one set.', Colors.orange);
      return;
    }
    setState(() {
      _exercises[exIndex].sets[setIndex].dispose();
      _exercises[exIndex].sets.removeAt(setIndex);
    });
  }

  void _showSetOptions(int exIndex, int setIndex) {
    final set = _exercises[exIndex].sets[setIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Set ${setIndex + 1} options',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: set.isWarmup
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: set.isWarmup
                        ? Colors.orange
                        : const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                title: Text(
                  set.isWarmup ? 'Remove warmup' : 'Mark as warmup',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                subtitle: Text(
                  set.isWarmup
                      ? 'This set will count towards volume'
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
                  _removeSet(exIndex, setIndex);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rest timer ────────────────────────────────────────────────────────────

  Future<void> _showRestPicker(int exIndex) async {
    int selMin = _exercises[exIndex].restSeconds ~/ 60;
    int selSec = _exercises[exIndex].restSeconds % 60;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Rest Timer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RestDropdown(
                label: 'MIN',
                value: selMin,
                items: List.generate(11, (i) => i),
                onChanged: (v) => setD(() => selMin = v!),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _RestDropdown(
                label: 'SEC',
                value: selSec,
                items: [0, 15, 30, 45],
                onChanged: (v) => setD(() => selSec = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {
                setState(() {
                  _exercises[exIndex].restCtrl.text = (selMin * 60 + selSec)
                      .toString();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add exercise ──────────────────────────────────────────────────────────

  Future<void> _navigateToAddExercise() async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );
    if (selected == null) return;

    if (_exercises.any((e) => e.exercise.id == selected.id)) {
      _snack('${selected.name} is already in the routine.', Colors.orange);
      return;
    }

    setState(() {
      _exercises.add(_DraftExercise(exercise: selected, sets: [_DraftSet()]));
    });
  }

  // ── Validate & save ───────────────────────────────────────────────────────

  String? _validate() {
    if (_nameController.text.trim().isEmpty) return 'Enter a routine name.';
    if (_exercises.isEmpty) return 'Add at least one exercise.';
    for (final ex in _exercises) {
      if (ex.sets.isEmpty) {
        return '${ex.exercise.name}: needs at least one set.';
      }
      for (final s in ex.sets) {
        final w = s.weight;
        if (w != null && w < 0) {
          return '${ex.exercise.name}: weight cannot be negative.';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final error = _validate();
    if (error != null) {
      _snack(error, Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final routineExercises = _exercises.asMap().entries.map((entry) {
        final ex = entry.value;

        // El backend almacena un único peso/reps target por ejercicio.
        // Usamos el primer set de trabajo (no warmup) como referencia.
        // Si todos son warmup, usamos el primero de todos.
        final workingSets = ex.sets.where((s) => !s.isWarmup).toList();
        final refSet = workingSets.isNotEmpty
            ? workingSets.first
            : ex.sets.first;

        return RoutineExercise(
          id: ex.routineExerciseId,
          exerciseId: ex.exercise.id,
          exerciseName: ex.exercise.name,
          orderIndex: entry.key + 1,
          sets: ex.sets.length,
          reps: refSet.reps ?? 10,
          restSeconds: ex.restSeconds,
          targetWeight: refSet.weight,
        );
      }).toList();

      final updated = Routine(
        id: widget.routine.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        userId: widget.routine.userId,
        exercises: routineExercises,
      );

      await WorkoutDependencies.routineRepository.updateRoutine(updated);

      if (mounted) {
        _snack('Routine updated!', Colors.green);
        Navigator.pop(context, true);
      }
    } on AuthenticationFailure catch (e) {
      _snack(e.message, Colors.red);
    } on NetworkFailure catch (e) {
      _snack(e.message, Colors.orange, retryable: true);
    } on ValidationFailure catch (e) {
      _snack(e.message, Colors.amber);
    } catch (e) {
      _snack('Could not save: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, Color color, {bool retryable = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        action: retryable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _save,
              )
            : null,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Edit Routine',
          style: TextStyle(fontWeight: FontWeight.w700),
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
                  onPressed: _save,
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Last session banner ───────────────────────────────────────
          if (widget.lastWorkout != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.blueAccent.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pre-loaded from last session · '
                      '${_fmtDate(widget.lastWorkout!.startTime)}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Name & description ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: const Color(0xFF1A1A1A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Routine Name',
                    hintStyle: TextStyle(color: Color(0xFF555555)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _descController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(color: Color(0xFF444444)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // ── Exercise list ─────────────────────────────────────────────
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 20),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                });
              },
              footer: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              itemCount: _exercises.length,
              itemBuilder: (context, exIndex) {
                final ex = _exercises[exIndex];
                return _ExerciseCard(
                  key: Key(ex.widgetKey),
                  draft: ex,
                  exIndex: exIndex,
                  onRemoveExercise: () =>
                      setState(() => _exercises.removeAt(exIndex)),
                  onAddSet: () => _addSet(exIndex),
                  onSetOptions: (setIndex) =>
                      _showSetOptions(exIndex, setIndex),
                  onRestTimer: () => _showRestPicker(exIndex),
                  dragHandle: ReorderableDragStartListener(
                    index: exIndex,
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
    );
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final _DraftExercise draft;
  final int exIndex;
  final VoidCallback onRemoveExercise;
  final VoidCallback onAddSet;
  final ValueChanged<int> onSetOptions;
  final VoidCallback onRestTimer;
  final Widget dragHandle;

  const _ExerciseCard({
    super.key,
    required this.draft,
    required this.exIndex,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onSetOptions,
    required this.onRestTimer,
    required this.dragHandle,
  });

  String _fmtRest(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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
            // ── Header ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.exercise.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueAccent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _fmtRest(draft.restSeconds),
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
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemoveExercise,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      size: 18,
                    ),
                  ),
                ),
                dragHandle,
              ],
            ),

            // ── Column headers ────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
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
                  SizedBox(width: 36),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 6),

            // ── Sets ──────────────────────────────────────────────────
            ...List.generate(draft.sets.length, (setIndex) {
              final s = draft.sets[setIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // Badge — tap for options
                    GestureDetector(
                      onTap: () => onSetOptions(setIndex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: s.isWarmup
                              ? Colors.orange.withValues(alpha: 0.15)
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: _SetField(
                        controller: s.weightCtrl,
                        hint: '0',
                        isDecimal: true,
                        accentColor: s.isWarmup
                            ? Colors.orange
                            : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: _SetField(
                        controller: s.repsCtrl,
                        hint: '10',
                        isDecimal: false,
                        accentColor: s.isWarmup ? Colors.orange : null,
                      ),
                    ),
                    const SizedBox(width: 8),

                    SizedBox(
                      width: 28,
                      child: GestureDetector(
                        onTap: () => onSetOptions(setIndex),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: Color(0xFF555555),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Add set ───────────────────────────────────────────────
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, color: Colors.blueAccent, size: 15),
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
                    horizontal: 14,
                    vertical: 5,
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

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDecimal;
  final Color? accentColor;

  const _SetField({
    required this.controller,
    required this.hint,
    required this.isDecimal,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: accent ?? Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 15),
        filled: true,
        fillColor: accent != null
            ? accent.withValues(alpha: 0.08)
            : const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: accent != null
              ? BorderSide(color: accent.withValues(alpha: 0.3), width: 1)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: accent != null
              ? BorderSide(color: accent.withValues(alpha: 0.3), width: 1)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 9),
        isDense: true,
      ),
    );
  }
}

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

// lib/features/workouts/presentation/screens/routines_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/di/core_dependencies.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/workout.dart';
import '../../domain/use_cases/get_routines.dart';
import '../../workout_dependencies.dart';
import 'active_workout_screen.dart';
import 'create_routine_screen.dart';
import 'edit_routine_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  late final GetRoutines _getRoutinesUseCase;

  List<Routine> _routines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getRoutinesUseCase = WorkoutDependencies.getRoutinesUseCase;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await CoreDependencies.sessionService.getUserId();
      if (userId == null || userId <= 0) {
        setState(() {
          _routines = [];
          _isLoading = false;
        });
        return;
      }
      final routines = await _getRoutinesUseCase(userId);
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is NetworkFailure
            ? e.message
            : e is AuthenticationFailure
            ? e.message
            : 'Could not load routines.';
        _isLoading = false;
      });
    }
  }

  // ── Reorder ───────────────────────────────────────────────────────────────

  void _onReorder(int oldIndex, int newIndex) {
    // ReorderableListView calls with newIndex already adjusted for the gap
    // created by removing the dragged item, so we correct for that.
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _routines.removeAt(oldIndex);
      _routines.insert(newIndex, item);
    });
  }

  // ── Last workout helper ───────────────────────────────────────────────────

  Future<Workout?> _fetchLastWorkout(int routineId) async {
    try {
      final userId = await CoreDependencies.sessionService.getUserId();
      if (userId == null || userId <= 0) return null;
      return await WorkoutDependencies.getWorkoutHistoryUseCase
          .getLastWorkoutForRoutine(userId, routineId);
    } catch (_) {
      return null;
    }
  }

  // ── Start empty workout ───────────────────────────────────────────────────

  Future<void> _confirmAndStartEmptyWorkout() async {
    final confirmed = await _showStartDialog(
      title: 'Start Empty Workout',
      subtitle: "You'll add exercises as you go. Ready to begin?",
    );
    if (!confirmed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveWorkoutScreen(selectedExercises: []),
      ),
    );
    _load();
  }

  // ── Start routine ─────────────────────────────────────────────────────────

  Future<void> _confirmAndStartRoutine(Routine routine) async {
    final confirmed = await _showStartDialog(
      title: 'Start ${routine.name}',
      subtitle: "This will load your last session's weights and reps. Ready?",
    );
    if (!confirmed || !mounted) return;

    Workout? lastWorkout;
    if (routine.id != null) lastWorkout = await _fetchLastWorkout(routine.id!);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          selectedExercises: routine.exercises.map((re) {
            return Exercise(
              id: re.exerciseId,
              name: re.exerciseName ?? '',
              description: '',
              primaryMuscle: '',
              category: '',
              secondaryMuscles: [],
            );
          }).toList(),
          baseRoutine: routine,
          previousWorkout: lastWorkout,
        ),
      ),
    );
    _load();
  }

  // ── Edit routine ──────────────────────────────────────────────────────────

  Future<void> _editRoutine(Routine routine) async {
    Workout? lastWorkout;
    if (routine.id != null) lastWorkout = await _fetchLastWorkout(routine.id!);
    if (!mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditRoutineScreen(routine: routine, lastWorkout: lastWorkout),
      ),
    );
    if (saved == true) _load();
  }

  // ── Delete routine ────────────────────────────────────────────────────────

  Future<void> _deleteRoutine(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Routine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${routine.name}"?'
          ' This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || routine.id == null) return;

    try {
      await WorkoutDependencies.deleteRoutineUseCase(routine.id!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${routine.name}" deleted.'),
            backgroundColor: const Color(0xFF2A2A2A),
          ),
        );
      }
    } on NetworkFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete routine. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Create routine ────────────────────────────────────────────────────────

  void _createRoutine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
    ).then((_) => _load());
  }

  // ── Start dialog ──────────────────────────────────────────────────────────

  Future<bool> _showStartDialog({
    required String title,
    required String subtitle,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Not now',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Let's go",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Train',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.flash_on_rounded,
                        label: 'Empty\nWorkout',
                        color: Colors.blueAccent,
                        onTap: _confirmAndStartEmptyWorkout,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'New\nRoutine',
                        color: const Color(0xFF00C896),
                        onTap: _createRoutine,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // "My Routines" label — with hint when list is non-empty
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'My Routines',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_routines.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '· hold & drag to reorder',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Body
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Could not load routines',
                  subtitle: _error!,
                  actionLabel: 'Retry',
                  onAction: _load,
                ),
              )
            else if (_routines.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'No routines yet',
                  subtitle:
                      'Create your first routine and start training with a plan.',
                  actionLabel: 'Create Routine',
                  onAction: _createRoutine,
                ),
              )
            else
              // SliverReorderableList for drag-to-reorder within a sliver context
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverReorderableList(
                  itemCount: _routines.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final routine = _routines[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(routine.id ?? routine.name),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RoutineCard(
                          routine: routine,
                          onStart: () => _confirmAndStartRoutine(routine),
                          onEdit: () => _editRoutine(routine),
                          onDelete: () => _deleteRoutine(routine),
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

// ── Routine card ──────────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = routine.exercises.length;
    final totalSets = routine.exercises.fold<int>(0, (s, e) => s + e.sets);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + action buttons ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: const Color(0xFF444444),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    routine.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                _IconBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF888888),
                  onTap: onEdit,
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  onTap: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),

            if (routine.description != null &&
                routine.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  routine.description!,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2E2E2E), height: 1),
            const SizedBox(height: 14),

            // ── Stats + Start button ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _StatChip(
                        icon: Icons.fitness_center_rounded,
                        label:
                            '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''}',
                      ),
                      _StatChip(
                        icon: Icons.repeat_rounded,
                        label: '$totalSets sets',
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Exercise name chips ───────────────────────────────────
            if (routine.exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...routine.exercises
                      .take(4)
                      .map(
                        (e) =>
                            _ExerciseChip(label: e.exerciseName ?? 'Exercise'),
                      ),
                  if (routine.exercises.length > 4)
                    _ExerciseChip(
                      label: '+${routine.exercises.length - 4} more',
                      highlighted: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _ExerciseChip({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.blueAccent.withValues(alpha: 0.15)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? Colors.blueAccent : const Color(0xFFAAAAAA),
          fontSize: 12,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

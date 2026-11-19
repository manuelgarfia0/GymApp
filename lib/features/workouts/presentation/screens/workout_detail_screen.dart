import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/settings/app_settings_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weight_converter.dart';
import '../../../../core/widgets/anatomical_muscle_heatmap.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_heatmap.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/workout.dart';
import '../../domain/use_cases/calculate_muscle_heatmap.dart';
import '../../domain/use_cases/evaluate_personal_records.dart';
import '../../workout_dependencies.dart';
import '../widgets/exercise_media_viewer.dart';

/// Muestra el diálogo de confirmación antes de eliminar definitivamente un
/// entrenamiento del historial.
Future<bool> showDeleteWorkoutConfirmDialog(
  BuildContext context,
  String workoutName,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.cardBg(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '¿Eliminar entrenamiento?',
            style: TextStyle(
              color: AppTheme.textPrimary(dialogContext),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Se eliminará "$workoutName" y todas sus series del historial. Esta acción no se puede deshacer.',
            style: TextStyle(
              color: AppTheme.textSecondary(dialogContext),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textSecondary(dialogContext)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Eliminar',
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

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final bool isPreview;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final List<PersonalRecordAchievement> personalRecords;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    this.isPreview = false,
    this.onConfirm,
    this.onCancel,
    this.personalRecords = const [],
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Map<int, Exercise> _exercisesById = const {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadExercisesCatalog();
  }

  Future<void> _confirmAndDelete() async {
    final workoutId = widget.workout.id;
    if (workoutId == null || workoutId <= 0 || _isDeleting) return;

    final confirmed = await showDeleteWorkoutConfirmDialog(
      context,
      widget.workout.name,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await WorkoutDependencies.deleteWorkoutUseCase(workoutId);
      WorkoutDependencies.notifyWorkoutSaved();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst(
            RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'),
            '',
          )
          .trim();
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                cleanMsg.isNotEmpty
                    ? cleanMsg
                    : 'No se pudo eliminar el entrenamiento',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    }
  }

  Future<void> _loadExercisesCatalog() async {
    try {
      final catalog = await WorkoutDependencies.getExercisesUseCase();
      if (!mounted) return;
      setState(() {
        _exercisesById = {for (final ex in catalog) ex.id: ex};
      });
    } catch (_) {
      // Mantiene datos básicos de fallback si no hay conexión o DI inicializada.
    }
  }

  Exercise _resolveExercise(int exerciseId, String name) {
    return _exercisesById[exerciseId] ??
        Exercise(
          id: exerciseId,
          name: name,
          description: '',
          primaryMuscle: '',
          category: '',
          secondaryMuscles: const [],
        );
  }

  List<Map<String, dynamic>> _groupedExercises() {
    final grouped = <int, Map<String, dynamic>>{};
    for (final set in widget.workout.sets) {
      if (!grouped.containsKey(set.exerciseId)) {
        grouped[set.exerciseId] = {
          'exerciseId': set.exerciseId,
          'name': set.exerciseName ?? 'Unknown Exercise',
          'notes': '',
          'sets': <WorkoutSet>[],
        };
      }
      if (set.notes != null && set.notes!.isNotEmpty) {
        grouped[set.exerciseId]!['notes'] = set.notes;
      }
      (grouped[set.exerciseId]!['sets'] as List<WorkoutSet>).add(set);
    }
    return grouped.values.toList();
  }

  // Cambio: Mostrar en formato HH:MM:SS
  String _duration() {
    if (widget.workout.endTime == null) return '--';
    final d = widget.workout.duration;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double _totalVolume() => widget.workout.sets
      .where((s) => !s.isWarmup)
      .fold(0, (sum, s) => sum + s.weight * s.reps);

  String _volumeLabel(WeightUnit unit) =>
      WeightConverter.formatVolume(_totalVolume(), unit);

  @override
  Widget build(BuildContext context) {
    final unit = AppSettingsScope.of(context).weightUnit;
    final bg = AppTheme.scaffoldBg(context);
    final cardBg = AppTheme.cardBg(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    final grouped = _groupedExercises();
    final sessionHeatmap = _exercisesById.isEmpty
        ? MuscleHeatmapData.empty
        : const CalculateMuscleHeatmap()(
            workouts: [widget.workout],
            exercisesById: _exercisesById,
            includeIncompleteSets: widget.workout.endTime == null,
          );
    final leadingWidgets = <Widget>[
      if (widget.personalRecords.isNotEmpty)
        _PersonalRecordsBanner(personalRecords: widget.personalRecords),
      if (!sessionHeatmap.isEmpty) ...[
        Text(
          'Músculos trabajados',
          style: TextStyle(
            color: primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AnatomicalMuscleHeatmap(
          singleData: sessionHeatmap,
          compact: true,
        ),
        const SizedBox(height: 16),
      ],
    ];
    final date = DateFormat('EEEE, MMM d, yyyy · HH:mm').format(
      widget.workout.startTime,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          widget.isPreview ? 'Workout Preview' : 'Workout Summary',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardBg,
        foregroundColor: primaryText,
        elevation: 0,
        leading: widget.isPreview
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              )
            : null,
        actions: (!widget.isPreview &&
                widget.workout.id != null &&
                widget.workout.id! > 0)
            ? [
                _isDeleting
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : IconButton(
                        key: const Key('workout_detail_delete_button'),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Eliminar entrenamiento',
                        onPressed: _confirmAndDelete,
                      ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            color: cardBg,
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.workout.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.timer_outlined,
                        label: _duration(),
                        sublabel: 'Duration',
                      ),
                    ),
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.fitness_center_rounded,
                        label: '${grouped.length}',
                        sublabel: 'Exercises',
                      ),
                    ),
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.repeat_rounded,
                        label: '${widget.workout.sets.length}',
                        sublabel: 'Total sets',
                      ),
                    ),
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.monitor_weight_outlined,
                        label: _volumeLabel(unit),
                        sublabel: 'Volume',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: leadingWidgets.length + grouped.length,
              itemBuilder: (context, index) {
                if (index < leadingWidgets.length) {
                  return leadingWidgets[index];
                }
                final ex = grouped[index - leadingWidgets.length];
                final exerciseId = ex['exerciseId'] as int;
                final name = ex['name'] as String;
                final notes = ex['notes'] as String;
                final sets = ex['sets'] as List<WorkoutSet>;
                final resolvedExercise = _resolveExercise(exerciseId, name);
                final prSetNumbers = widget.personalRecords
                    .where((pr) => pr.exerciseId == exerciseId)
                    .map((pr) => pr.setNumber)
                    .toSet();
                return _ExerciseCard(
                  exercise: resolvedExercise,
                  notes: notes,
                  sets: sets,
                  prSetNumbers: prSetNumbers,
                  onTapExercise: () =>
                      showExerciseDetailSheet(context, resolvedExercise),
                );
              },
            ),
          ),

          if (widget.isPreview)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor(context)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel ??
                            () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(color: secondaryText, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: widget.onConfirm ??
                            () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Finish Workout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final String notes;
  final List<WorkoutSet> sets;
  final Set<int> prSetNumbers;
  final VoidCallback onTapExercise;

  const _ExerciseCard({
    required this.exercise,
    required this.notes,
    required this.sets,
    this.prSetNumbers = const {},
    required this.onTapExercise,
  });

  double _exerciseVolume() => sets
      .where((s) => !s.isWarmup)
      .fold(0, (sum, s) => sum + s.weight * s.reps);

  double _bestEstimated1Rm() {
    double best = 0;
    for (final s in sets) {
      if (s.isWarmup || s.weight <= 0 || s.reps <= 0) continue;
      final est = EvaluatePersonalRecords.calculateEstimated1Rm(
        s.weight,
        s.reps,
      );
      if (est > best) best = est;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final unit = AppSettingsScope.of(context).weightUnit;
    final cardBg = AppTheme.cardBg(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final mutedText = AppTheme.textMuted(context);

    int workingSetNumber = 0;
    final volumeLabel = WeightConverter.formatVolume(_exerciseVolume(), unit);
    final best1Rm = _bestEstimated1Rm();
    final best1RmDisplay = WeightConverter.fromKg(best1Rm, unit).round();
    final hasAnyPr = prSetNumbers.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: AppTheme.isDark(context)
            ? null
            : Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExerciseThumbnail(
                  exercise: exercise,
                  size: 38,
                  onTap: onTapExercise,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onTapExercise,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sets.length} series · $volumeLabel'
                          '${best1Rm > 0 ? ' · Mejor 1RM ~$best1RmDisplay ${unit.label}' : ''}',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasAnyPr) const _DetailPrBadge(),
              ],
            ),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📝 $notes',
                style: const TextStyle(
                  color: Colors.amber,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                const SizedBox(width: 38),
                Expanded(
                  flex: 2,
                  child: Text(
                    unit.headerLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '1RM EST.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (hasAnyPr) const SizedBox(width: 56),
              ],
            ),
            Divider(color: AppTheme.borderColor(context)),

            ...sets.map((s) {
              final isWarmup = s.isWarmup;
              if (!isWarmup) workingSetNumber++;
              final isPr = !isWarmup && prSetNumbers.contains(s.setNumber);

              final weightStr = ExerciseHistoricalBest.formatWeightInUnit(
                s.weight,
                unit,
              );
              final est1Rm = isWarmup || s.weight <= 0 || s.reps <= 0
                  ? 0.0
                  : EvaluatePersonalRecords.calculateEstimated1Rm(
                      s.weight,
                      s.reps,
                    );
              final est1RmStr = isWarmup
                  ? 'Calent.'
                  : est1Rm > 0
                  ? '${WeightConverter.fromKg(est1Rm, unit).round()} ${unit.label}'
                  : '—';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isWarmup
                            ? Colors.orange.withValues(alpha: 0.12)
                            : isPr
                            ? Colors.amber.withValues(alpha: 0.16)
                            : AppTheme.elevatedBg(context),
                        borderRadius: BorderRadius.circular(6),
                        border: isWarmup
                            ? Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
                                width: 1,
                              )
                            : isPr
                            ? Border.all(
                                color: Colors.amber.withValues(alpha: 0.65),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isWarmup
                            ? const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.orange,
                                size: 15,
                              )
                            : Text(
                                '$workingSetNumber',
                                style: TextStyle(
                                  color: isPr ? Colors.amber : primaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    Expanded(
                      flex: 2,
                      child: Text(
                        weightStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isWarmup
                              ? secondaryText
                              : isPr
                              ? Colors.amber
                              : primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Text(
                        '${s.reps}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isWarmup
                              ? secondaryText
                              : isPr
                              ? Colors.amber
                              : primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Text(
                        est1RmStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isWarmup
                              ? Colors.orange.withValues(alpha: 0.75)
                              : isPr
                              ? Colors.amber
                              : secondaryText,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    if (hasAnyPr)
                      SizedBox(
                        width: 56,
                        child: isPr
                            ? const _DetailPrBadge()
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              );
            }),

            if (sets.any((s) => s.isWarmup)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.orange,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Warmup sets excluded from volume',
                    style: TextStyle(
                      color: Colors.orange.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
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

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
        ),
      ],
    );
  }
}

class _PersonalRecordsBanner extends StatelessWidget {
  final List<PersonalRecordAchievement> personalRecords;

  const _PersonalRecordsBanner({required this.personalRecords});

  /// Consolida el mejor PR logrado por cada ejercicio dentro de la sesión.
  List<PersonalRecordAchievement> _bestPerExercise() {
    final best = <int, PersonalRecordAchievement>{};
    for (final pr in personalRecords) {
      final current = best[pr.exerciseId];
      if (current == null || pr.estimated1Rm >= current.estimated1Rm) {
        best[pr.exerciseId] = pr;
      }
    }
    return best.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final unit = AppSettingsScope.of(context).weightUnit;
    final groupedPrs = _bestPerExercise();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.16),
            AppTheme.isDark(context)
                ? const Color(0xFF261E0A)
                : Colors.amber.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🏆 Nuevos Récords Personales (${groupedPrs.length})',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...groupedPrs.map((pr) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.amber,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pr.exerciseName,
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              pr.performanceLabelFor(unit),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          pr.improvementLabelFor(unit),
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailPrBadge extends StatelessWidget {
  const _DetailPrBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: const Text(
        '🏆 PR',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.amber,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

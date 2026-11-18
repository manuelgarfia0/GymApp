import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/anatomical_muscle_heatmap.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_heatmap.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/workout.dart';
import '../../domain/use_cases/calculate_muscle_heatmap.dart';
import '../../domain/use_cases/evaluate_personal_records.dart';
import '../../workout_dependencies.dart';
import '../widgets/exercise_media_viewer.dart';

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

  @override
  void initState() {
    super.initState();
    _loadExercisesCatalog();
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

  // Cambio: antes abreviaba con "k" a partir de 1000 kg.
  // Ahora muestra siempre el número completo ("1234 kg").
  String _volumeLabel() {
    final v = _totalVolume();
    return '${v.toStringAsFixed(0)} kg';
  }

  @override
  Widget build(BuildContext context) {
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
        const Text(
          'Músculos trabajados',
          style: TextStyle(
            color: Colors.white,
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.isPreview ? 'Workout Preview' : 'Workout Summary',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: widget.isPreview
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            color: const Color(0xFF1E1E1E),
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
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
                        label: _volumeLabel(),
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
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(
                  top: BorderSide(color: Color(0xFF2A2A2A)),
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
                        child: const Text('Back',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                        child: const Text('Finish Workout',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
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
    int workingSetNumber = 0;
    final volumeStr = _exerciseVolume().toStringAsFixed(0);
    final best1Rm = _bestEstimated1Rm();
    final hasAnyPr = prSetNumbers.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
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
                          '${sets.length} series · $volumeStr kg'
                          '${best1Rm > 0 ? ' · Mejor 1RM ~${best1Rm.round()} kg' : ''}',
                          style: const TextStyle(
                            color: Color(0xFF888888),
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
                const Expanded(
                  flex: 2,
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    '1RM EST.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (hasAnyPr) const SizedBox(width: 56),
              ],
            ),
            const Divider(color: Color(0xFF2A2A2A)),

            ...sets.map((s) {
              final isWarmup = s.isWarmup;
              if (!isWarmup) workingSetNumber++;
              final isPr = !isWarmup && prSetNumbers.contains(s.setNumber);

              final weightStr = ExerciseHistoricalBest.formatWeight(s.weight);
              final est1Rm = isWarmup || s.weight <= 0 || s.reps <= 0
                  ? 0.0
                  : EvaluatePersonalRecords.calculateEstimated1Rm(
                      s.weight,
                      s.reps,
                    );
              final est1RmStr = isWarmup
                  ? 'Calent.'
                  : est1Rm > 0
                  ? '${est1Rm.round()} kg'
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
                            : const Color(0xFF252525),
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
                                  color: isPr ? Colors.amber : Colors.white,
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
                              ? const Color(0xFF888888)
                              : isPr
                              ? Colors.amber.shade200
                              : Colors.white,
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
                              ? const Color(0xFF888888)
                              : isPr
                              ? Colors.amber.shade200
                              : Colors.white,
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
                              ? Colors.amber.shade200
                              : const Color(0xFF9E9E9E),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          sublabel,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
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
    final groupedPrs = _bestPerExercise();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.16),
            const Color(0xFF261E0A),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              pr.performanceLabel,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          pr.improvementLabel,
                          style: TextStyle(
                            color: Colors.amber.shade100.withValues(alpha: 0.8),
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

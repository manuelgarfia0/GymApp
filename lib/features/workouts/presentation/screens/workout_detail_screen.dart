import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/workout.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  final bool isPreview;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const WorkoutDetailScreen({
    super.key, 
    required this.workout,
    this.isPreview = false,
    this.onConfirm,
    this.onCancel,
  });

  List<Map<String, dynamic>> _groupedExercises() {
    final grouped = <int, Map<String, dynamic>>{};
    for (final set in workout.sets) {
      if (!grouped.containsKey(set.exerciseId)) {
        grouped[set.exerciseId] = {
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
    if (workout.endTime == null) return '--';
    final d = workout.duration;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double _totalVolume() => workout.sets
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
    final date = DateFormat('EEEE, MMM d, yyyy').format(workout.startTime);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          isPreview ? 'Workout Preview' : 'Workout Summary',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: isPreview 
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
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  workout.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryChip(
                      icon: Icons.timer_outlined,
                      label: _duration(),
                      sublabel: 'Duration',
                    ),
                    _SummaryChip(
                      icon: Icons.repeat_rounded,
                      label: '${workout.sets.length}',
                      sublabel: 'Total sets',
                    ),
                    _SummaryChip(
                      icon: Icons.monitor_weight_outlined,
                      label: _volumeLabel(),
                      sublabel: 'Volume',
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
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final ex = grouped[index];
                final name = ex['name'] as String;
                final notes = ex['notes'] as String;
                final sets = ex['sets'] as List<WorkoutSet>;
                return _ExerciseCard(name: name, notes: notes, sets: sets);
              },
            ),
          ),

          if (isPreview)
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
                        onPressed: onCancel ?? () => Navigator.pop(context, false),
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
                        onPressed: onConfirm ?? () => Navigator.pop(context, true),
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
  final String name;
  final String notes;
  final List<WorkoutSet> sets;

  const _ExerciseCard({
    required this.name,
    required this.notes,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    int workingSetNumber = 0;

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
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
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

            const Row(
              children: [
                SizedBox(width: 40),
                Expanded(
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
                Expanded(
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
              ],
            ),
            const Divider(color: Color(0xFF2A2A2A)),

            ...sets.map((s) {
              final isWarmup = s.isWarmup;
              if (!isWarmup) workingSetNumber++;

              final weightStr = s.weight == s.weight.toInt()
                  ? s.weight.toInt().toString()
                  : s.weight.toString();

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
                            : const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(6),
                        border: isWarmup
                            ? Border.all(
                                color: Colors.orange.withValues(alpha: 0.4),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        weightStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isWarmup
                              ? const Color(0xFF888888)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        '${s.reps}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isWarmup
                              ? const Color(0xFF888888)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
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

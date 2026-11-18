import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/use_cases/get_user_stats.dart';

/// Matriz anual interactiva (7 días × ~53 semanas) que visualiza los últimos
/// 365 días de constancia y volumen de entrenamiento del usuario.
class WorkoutConsistencyHeatmap extends StatefulWidget {
  final Map<DateTime, double> volumeByDate;
  final Map<DateTime, List<ProfileWorkoutSummary>> workoutsByDate;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final int activeDaysLastYear;
  final int longestStreak;
  final DateTime? anchorDate;

  const WorkoutConsistencyHeatmap({
    super.key,
    required this.volumeByDate,
    required this.workoutsByDate,
    required this.selectedDay,
    required this.onDaySelected,
    required this.activeDaysLastYear,
    required this.longestStreak,
    this.anchorDate,
  });

  /// Calcula el nivel de intensidad cromática `0..4` según el volumen diario.
  static int intensityLevelForVolume(
    double volume,
    double maxVolume, {
    bool hasWorkout = false,
  }) {
    if (volume <= 0) {
      return hasWorkout ? 1 : 0;
    }
    if (maxVolume <= 0) return 1;
    final ratio = volume / maxVolume;
    if (ratio <= 0.25) return 1;
    if (ratio <= 0.50) return 2;
    if (ratio <= 0.75) return 3;
    return 4;
  }

  static const List<Color> _palette = [
    Color(0xFF262626), // Nivel 0: sin entrenamiento
    Color(0xFF173A5E), // Nivel 1: volumen ligero
    Color(0xFF1E5AA8), // Nivel 2: volumen medio
    Color(0xFF2979FF), // Nivel 3: volumen alto
    Color(0xFF60B5FF), // Nivel 4: volumen máximo
  ];

  static const List<String> _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const List<String> _monthAbbr = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  State<WorkoutConsistencyHeatmap> createState() =>
      _WorkoutConsistencyHeatmapState();
}

class _WorkoutConsistencyHeatmapState extends State<WorkoutConsistencyHeatmap> {
  final ScrollController _scrollController = ScrollController();

  static const double _cellSize = 13.0;
  static const double _cellGap = 3.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  Widget build(BuildContext context) {
    final rawNow = widget.anchorDate ?? DateTime.now();
    final today = _normalizeDate(rawNow);
    final rangeStart = today.subtract(const Duration(days: 364));
    final gridStart = rangeStart.subtract(
      Duration(days: rangeStart.weekday - DateTime.monday),
    );
    final totalGridDays = today.difference(gridStart).inDays + 1;
    final weekCount = (totalGridDays + 6) ~/ 7;

    final normalizedVolumes = <DateTime, double>{};
    double maxVolume = 0;
    widget.volumeByDate.forEach((date, vol) {
      final key = _normalizeDate(date);
      normalizedVolumes[key] = (normalizedVolumes[key] ?? 0) + vol;
      if (!key.isBefore(rangeStart) &&
          !key.isAfter(today) &&
          normalizedVolumes[key]! > maxVolume) {
        maxVolume = normalizedVolumes[key]!;
      }
    });

    final selectedNormalized =
        widget.selectedDay != null ? _normalizeDate(widget.selectedDay!) : null;
    final monthHeaders = _buildMonthHeaders(gridStart, rangeStart, today, weekCount);

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MetricPill(
                  icon: Icons.calendar_today_rounded,
                  label: '${widget.activeDaysLastYear} días activos (365d)',
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                _MetricPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Racha máx: ${widget.longestStreak}d',
                  color: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 18, right: 6),
                  child: Column(
                    children: List.generate(7, (row) {
                      final showLabel = row == 0 || row == 2 || row == 4 || row == 6;
                      return SizedBox(
                        height: _cellSize + _cellGap,
                        width: 14,
                        child: Center(
                          child: Text(
                            showLabel
                                ? WorkoutConsistencyHeatmap._weekdayLabels[row]
                                : '',
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(weekCount, (w) {
                            return SizedBox(
                              width: _cellSize + _cellGap,
                              height: 18,
                              child: monthHeaders[w] != null
                                  ? Text(
                                      monthHeaders[w]!,
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(weekCount, (weekIndex) {
                            return Column(
                              children: List.generate(7, (dayOffset) {
                                final cellDate = gridStart.add(
                                  Duration(days: weekIndex * 7 + dayOffset),
                                );
                                if (cellDate.isBefore(rangeStart) ||
                                    cellDate.isAfter(today)) {
                                  return const SizedBox(
                                    width: _cellSize + _cellGap,
                                    height: _cellSize + _cellGap,
                                  );
                                }

                                final vol = normalizedVolumes[cellDate] ?? 0;
                                final dayWorkouts =
                                    widget.workoutsByDate[cellDate] ?? const [];
                                final level = WorkoutConsistencyHeatmap
                                    .intensityLevelForVolume(
                                  vol,
                                  maxVolume,
                                  hasWorkout: dayWorkouts.isNotEmpty,
                                );
                                final isSelected = selectedNormalized == cellDate;
                                final color =
                                    WorkoutConsistencyHeatmap._palette[level];

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: _cellGap,
                                    bottom: _cellGap,
                                  ),
                                  child: Tooltip(
                                    message: _tooltipMessage(
                                      cellDate,
                                      dayWorkouts.length,
                                      vol,
                                    ),
                                    child: GestureDetector(
                                      key: Key(
                                        'heatmap_cell_${cellDate.year}_${cellDate.month}_${cellDate.day}',
                                      ),
                                      onTap: () => widget.onDaySelected(cellDate),
                                      child: Container(
                                        width: _cellSize,
                                        height: _cellSize,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(3),
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.amberAccent,
                                                  width: 1.6,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSelectionSummary(selectedNormalized, normalizedVolumes),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Menos',
                      style: TextStyle(color: Color(0xFF777777), fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    ...List.generate(
                      WorkoutConsistencyHeatmap._palette.length,
                      (index) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: WorkoutConsistencyHeatmap._palette[index],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Más',
                      style: TextStyle(color: Color(0xFF777777), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(
    DateTime? selectedDay,
    Map<DateTime, double> volumes,
  ) {
    if (selectedDay == null) {
      return const Text(
        'Pulsa un día para ver detalle',
        style: TextStyle(color: Color(0xFF888888), fontSize: 11),
        overflow: TextOverflow.ellipsis,
      );
    }

    final workoutsCount = widget.workoutsByDate[selectedDay]?.length ?? 0;
    final volume = volumes[selectedDay] ?? 0;
    final dateStr =
        '${selectedDay.day} ${WorkoutConsistencyHeatmap._monthAbbr[selectedDay.month - 1]} ${selectedDay.year}';
    final detail = workoutsCount == 0
        ? '$dateStr · Sin actividad'
        : '$dateStr · $workoutsCount entreno${workoutsCount > 1 ? 's' : ''} · ${volume.toStringAsFixed(0)} kg';

    return Text(
      detail,
      style: TextStyle(
        color: workoutsCount > 0 ? Colors.white : const Color(0xFF888888),
        fontSize: 11,
        fontWeight: workoutsCount > 0 ? FontWeight.w600 : FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Map<int, String> _buildMonthHeaders(
    DateTime gridStart,
    DateTime rangeStart,
    DateTime today,
    int weekCount,
  ) {
    final labels = <int, String>{};
    int? lastMonth;
    int lastLabeledWeek = -4;

    for (int w = 0; w < weekCount; w++) {
      final weekStart = gridStart.add(Duration(days: w * 7));
      DateTime? representative;
      for (int d = 0; d < 7; d++) {
        final candidate = weekStart.add(Duration(days: d));
        if (!candidate.isBefore(rangeStart) && !candidate.isAfter(today)) {
          representative = candidate;
          break;
        }
      }
      if (representative == null) continue;

      if (representative.month != lastMonth && (w - lastLabeledWeek) >= 3) {
        labels[w] = WorkoutConsistencyHeatmap._monthAbbr[representative.month - 1];
        lastLabeledWeek = w;
      }
      lastMonth = representative.month;
    }
    return labels;
  }

  String _tooltipMessage(DateTime day, int workoutCount, double volume) {
    final formatted = DateFormat('dd/MM/yyyy').format(day);
    if (workoutCount == 0) return '$formatted: Descanso';
    return '$formatted: $workoutCount entreno(s) · ${volume.toStringAsFixed(0)} kg';
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

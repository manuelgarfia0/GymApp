import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/workouts/domain/entities/muscle_heatmap.dart';
import '../settings/app_settings_scope.dart';
import '../theme/app_theme.dart';
import '../utils/weight_converter.dart';

/// Mapa de calor anatómico interactivo del cuerpo humano (vista frontal y espalda).
///
/// Muestra las regiones musculares coloreadas en 5 niveles de intensidad según
/// las series efectivas y volumen trabajados, con selección táctil sobre el
/// cuerpo o mediante chips para inspeccionar series, volumen y ejercicios.
class AnatomicalMuscleHeatmap extends StatefulWidget {
  final Map<MuscleHeatmapRange, MuscleHeatmapData>? heatmapsByRange;
  final MuscleHeatmapData? singleData;
  final MuscleHeatmapRange initialRange;
  final String? subtitle;
  final bool compact;

  const AnatomicalMuscleHeatmap({
    super.key,
    this.heatmapsByRange,
    this.singleData,
    this.initialRange = MuscleHeatmapRange.last30Days,
    this.subtitle,
    this.compact = false,
  });

  /// Paleta térmica de 5 niveles (`0 = sin actividad` .. `4 = máximo`).
  static const List<Color> heatPalette = [
    Color(0xFF2C313A), // Nivel 0: sin actividad
    Color(0xFFF59E0B), // Nivel 1: ligero (ámbar)
    Color(0xFFFB7124), // Nivel 2: moderado (naranja)
    Color(0xFFEF4444), // Nivel 3: alto (rojo intenso)
    Color(0xFFFF1E56), // Nivel 4: máximo (carmín vibrante)
  ];

  static String intensityLabel(int level) {
    switch (level) {
      case 1:
        return 'Ligero';
      case 2:
        return 'Moderado';
      case 3:
        return 'Alto';
      case 4:
        return 'Máximo';
      default:
        return 'Sin entreno';
    }
  }

  @override
  State<AnatomicalMuscleHeatmap> createState() =>
      _AnatomicalMuscleHeatmapState();
}

class _AnatomicalMuscleHeatmapState extends State<AnatomicalMuscleHeatmap> {
  late MuscleHeatmapRange _selectedRange;
  MuscleGroupKey? _selectedMuscle;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  @override
  void didUpdateWidget(covariant AnatomicalMuscleHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedMuscle != null) {
      final activity = _activeData.activityFor(_selectedMuscle!);
      if (activity.effectiveSets <= 0 && _activeData.isEmpty) {
        _selectedMuscle = null;
      }
    }
  }

  MuscleHeatmapData get _activeData {
    if (widget.singleData != null) {
      return widget.singleData!;
    }
    return widget.heatmapsByRange?[_selectedRange] ?? MuscleHeatmapData.empty;
  }

  void _selectRange(MuscleHeatmapRange range) {
    if (_selectedRange == range) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRange = range;
      final nextData = widget.heatmapsByRange?[range] ?? MuscleHeatmapData.empty;
      if (_selectedMuscle != null &&
          nextData.activityFor(_selectedMuscle!).effectiveSets <= 0) {
        _selectedMuscle = null;
      }
    });
  }

  void _toggleMuscle(MuscleGroupKey key) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMuscle = _selectedMuscle == key ? null : key;
    });
  }

  void _handleCanvasTap(
    Offset localPosition,
    Size size, {
    required bool isBack,
  }) {
    final normalized = _BodyGeometry.toNormalizedPoint(localPosition, size);
    if (normalized == null) return;

    final regions = isBack
        ? _BodyGeometry.backRegions
        : _BodyGeometry.frontRegions;

    for (final region in regions) {
      if (region.hitPath.contains(normalized)) {
        _toggleMuscle(region.key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = AppSettingsScope.of(context).weightUnit;
    final data = _activeData;
    final activeMuscles = data.activeMusclesSorted;
    final figureHeight = widget.compact ? 236.0 : 286.0;
    final padding = widget.compact ? 14.0 : 16.0;

    return Card(
      color: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.singleData == null && widget.heatmapsByRange != null) ...[
              _buildRangeSelector(context),
              const SizedBox(height: 14),
            ],
            SizedBox(
              height: figureHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _FigurePanel(
                      canvasKey: const Key('muscle_canvas_front'),
                      title: 'FRONTAL',
                      isBack: false,
                      data: data,
                      selectedMuscle: _selectedMuscle,
                      onTapUp: (pos, size) =>
                          _handleCanvasTap(pos, size, isBack: false),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    color: AppTheme.borderColor(context),
                  ),
                  Expanded(
                    child: _FigurePanel(
                      canvasKey: const Key('muscle_canvas_back'),
                      title: 'ESPALDA',
                      isBack: true,
                      data: data,
                      selectedMuscle: _selectedMuscle,
                      onTapUp: (pos, size) =>
                          _handleCanvasTap(pos, size, isBack: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(context),
            if (activeMuscles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: activeMuscles.map((activity) {
                  final selected = _selectedMuscle == activity.muscle;
                  final heatColor = AnatomicalMuscleHeatmap
                      .heatPalette[activity.intensityLevel.clamp(0, 4)];
                  return InkWell(
                    key: Key('muscle_chip_${activity.muscle.name}'),
                    onTap: () => _toggleMuscle(activity.muscle),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? heatColor.withValues(alpha: 0.24)
                            : AppTheme.elevatedBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? heatColor
                              : heatColor.withValues(alpha: 0.45),
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: heatColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activity.muscle.displayNameEs,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.textPrimary(context)
                                  : AppTheme.textSecondary(context),
                              fontSize: 11.5,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailPanel(context, data, unit),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: MuscleHeatmapRange.values.map((range) {
          final selected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              key: Key('muscle_range_${range.name}'),
              onTap: () => _selectRange(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? Colors.blueAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range.labelEs,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondary(context),
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Intensidad',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 11,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sin entreno',
                style: TextStyle(
                  color: AppTheme.textMuted(context),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 5),
              ...List.generate(
                AnatomicalMuscleHeatmap.heatPalette.length,
                (index) => Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: AnatomicalMuscleHeatmap.heatPalette[index],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Máximo',
                style: TextStyle(
                  color: AppTheme.textMuted(context),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel(
    BuildContext context,
    MuscleHeatmapData data,
    WeightUnit unit,
  ) {
    final panelBg = AppTheme.scaffoldBg(context);
    final border = AppTheme.borderColor(context);

    if (data.isEmpty) {
      return Container(
        key: const Key('muscle_detail_panel'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.textSecondary(context),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin entrenamientos en este periodo',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedMuscle == null) {
      final topName = data.topMuscle?.displayNameEs;
      final hint = topName != null
          ? 'Toca un músculo del cuerpo para ver sus series, volumen y ejercicios · Destacado: $topName'
          : 'Toca un músculo del cuerpo para ver sus series, volumen y ejercicios';
      return Container(
        key: const Key('muscle_detail_panel'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.touch_app_rounded,
              color: Colors.blueAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activity = data.activityFor(_selectedMuscle!);
    final levelColor = AnatomicalMuscleHeatmap
        .heatPalette[activity.intensityLevel.clamp(0, 4)];
    final levelText = AnatomicalMuscleHeatmap.intensityLabel(
      activity.intensityLevel,
    );

    return Container(
      key: const Key('muscle_detail_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.55),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.muscle.displayNameEs,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: levelColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  levelText,
                  style: TextStyle(
                    color: activity.intensityLevel == 0
                        ? AppTheme.textSecondary(context)
                        : levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _DetailStat(
                label: 'Primarias',
                value:
                    '${activity.primarySets} ${activity.primarySets == 1 ? 'serie' : 'series'}',
              ),
              if (activity.secondarySets > 0)
                _DetailStat(
                  label: 'Secundarias',
                  value:
                      '${activity.secondarySets} ${activity.secondarySets == 1 ? 'serie' : 'series'}',
                ),
              _DetailStat(
                label: 'Volumen',
                value: WeightConverter.formatVolume(activity.totalVolume, unit),
              ),
            ],
          ),
          if (activity.exercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: border, height: 1),
            const SizedBox(height: 8),
            ...activity.exercises.take(5).map(
                  (ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ex.exerciseName,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (ex.isPrimary
                                    ? Colors.blueAccent
                                    : Colors.grey)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ex.isPrimary ? 'Primario' : 'Secundario',
                            style: TextStyle(
                              color: ex.isPrimary
                                  ? Colors.blueAccent
                                  : AppTheme.textSecondary(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ex.sets}s · ${WeightConverter.formatVolume(ex.volume, unit)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Sin series registradas para este músculo en el periodo actual.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigurePanel extends StatelessWidget {
  final Key canvasKey;
  final String title;
  final bool isBack;
  final MuscleHeatmapData data;
  final MuscleGroupKey? selectedMuscle;
  final void Function(Offset localPosition, Size size) onTapUp;

  const _FigurePanel({
    required this.canvasKey,
    required this.title,
    required this.isBack,
    required this.data,
    required this.selectedMuscle,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF8C94A4),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return GestureDetector(
                key: canvasKey,
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    onTapUp(details.localPosition, canvasSize),
                child: CustomPaint(
                  size: canvasSize,
                  painter: _AnatomicalFigurePainter(
                    isBack: isBack,
                    data: data,
                    selectedMuscle: selectedMuscle,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnatomicalFigurePainter extends CustomPainter {
  final bool isBack;
  final MuscleHeatmapData data;
  final MuscleGroupKey? selectedMuscle;

  _AnatomicalFigurePainter({
    required this.isBack,
    required this.data,
    required this.selectedMuscle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final transform = _BodyGeometry.computeTransform(size);
    canvas.save();
    canvas.translate(transform.offsetX, transform.offsetY);
    canvas.scale(transform.scale);

    // 1. Silueta base del cuerpo humano
    final silhouetteFill = Paint()
      ..color = const Color(0xFF232730)
      ..style = PaintingStyle.fill;
    final silhouetteStroke = Paint()
      ..color = const Color(0xFF3A4150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_BodyGeometry.silhouettePath, silhouetteFill);
    canvas.drawPath(_BodyGeometry.silhouettePath, silhouetteStroke);

    // Detalle anatómico sutil en cabeza / nuca y articulaciones
    final detailPaint = Paint()
      ..color = const Color(0xFF3A4150).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    if (isBack) {
      canvas.drawLine(
        const Offset(100, 62),
        const Offset(100, 174),
        detailPaint,
      );
    } else {
      canvas.drawLine(
        const Offset(87, 74),
        const Offset(113, 74),
        detailPaint,
      );
    }

    // 2. Regiones musculares coloreadas según intensidad
    final regions = isBack
        ? _BodyGeometry.backRegions
        : _BodyGeometry.frontRegions;

    for (final region in regions) {
      final activity = data.activityFor(region.key);
      final level = activity.intensityLevel.clamp(0, 4);
      final isSelected = selectedMuscle == region.key;
      final fillColor = AnatomicalMuscleHeatmap.heatPalette[level];

      final fillPaint = Paint()
        ..color = level == 0
            ? fillColor.withValues(alpha: 0.85)
            : fillColor.withValues(alpha: isSelected ? 0.98 : 0.88)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isSelected
            ? Colors.white
            : (level == 0
                ? const Color(0xFF3A4150)
                : fillColor.withValues(alpha: 0.95))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.1 : 0.9
        ..strokeJoin = StrokeJoin.round;

      for (final path in region.visualPaths) {
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnatomicalFigurePainter oldDelegate) {
    return oldDelegate.isBack != isBack ||
        oldDelegate.data != data ||
        oldDelegate.selectedMuscle != selectedMuscle;
  }
}

class _BodyTransform {
  final double scale;
  final double offsetX;
  final double offsetY;

  const _BodyTransform({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

class _MuscleRegion {
  final MuscleGroupKey key;
  final Path hitPath;
  final List<Path> visualPaths;

  const _MuscleRegion({
    required this.key,
    required this.hitPath,
    required this.visualPaths,
  });
}

/// Geometría normalizada `200 × 420` de las vistas anatómicas frontal y posterior.
class _BodyGeometry {
  static const double baseWidth = 200.0;
  static const double baseHeight = 420.0;

  static _BodyTransform computeTransform(Size size) {
    final scale = math.min(size.width / baseWidth, size.height / baseHeight);
    final offsetX = (size.width - baseWidth * scale) / 2.0;
    final offsetY = (size.height - baseHeight * scale) / 2.0;
    return _BodyTransform(scale: scale, offsetX: offsetX, offsetY: offsetY);
  }

  static Offset? toNormalizedPoint(Offset localPos, Size size) {
    if (size.isEmpty) return null;
    final t = computeTransform(size);
    if (t.scale <= 0) return null;
    final nx = (localPos.dx - t.offsetX) / t.scale;
    final ny = (localPos.dy - t.offsetY) / t.scale;
    if (nx < 0 || nx > baseWidth || ny < 0 || ny > baseHeight) {
      return null;
    }
    return Offset(nx, ny);
  }

  static final Path silhouettePath = _buildSilhouette();
  static final List<_MuscleRegion> frontRegions = _buildFrontRegions();
  static final List<_MuscleRegion> backRegions = _buildBackRegions();

  static Path _buildSilhouette() {
    final p = Path();
    // Cabeza ovalada
    p.addOval(
      Rect.fromCenter(center: const Offset(100, 31), width: 28, height: 36),
    );

    // Cuerpo simétrico empezando en cuello derecho -> brazo derecho -> pierna derecha ->
    // pierna izquierda -> brazo izquierdo -> cuello izquierdo
    final body = Path()
      ..moveTo(109, 47)
      ..lineTo(111, 61)
      ..cubicTo(118, 66, 134, 69, 147, 74)
      ..cubicTo(157, 78, 160, 92, 158, 108)
      ..lineTo(154, 152)
      ..cubicTo(156, 166, 157, 182, 154, 212)
      ..cubicTo(158, 222, 158, 237, 153, 242)
      ..cubicTo(148, 245, 144, 236, 144, 214)
      ..lineTo(138, 158)
      ..lineTo(138, 108)
      ..cubicTo(136, 132, 132, 152, 128, 170)
      ..cubicTo(133, 188, 136, 206, 134, 236)
      ..cubicTo(132, 266, 129, 286, 126, 304)
      ..cubicTo(130, 326, 131, 344, 125, 368)
      ..lineTo(121, 392)
      ..cubicTo(125, 401, 127, 409, 121, 412)
      ..lineTo(109, 412)
      ..lineTo(108, 392)
      ..cubicTo(106, 362, 107, 336, 109, 305)
      ..cubicTo(106, 274, 105, 244, 102, 216)
      ..lineTo(100, 215)
      ..lineTo(98, 216)
      ..cubicTo(95, 244, 94, 274, 91, 305)
      ..cubicTo(93, 336, 94, 362, 92, 392)
      ..lineTo(91, 412)
      ..lineTo(79, 412)
      ..cubicTo(73, 409, 75, 401, 79, 392)
      ..lineTo(75, 368)
      ..cubicTo(69, 344, 70, 326, 74, 304)
      ..cubicTo(71, 286, 68, 266, 66, 236)
      ..cubicTo(64, 206, 67, 188, 72, 170)
      ..cubicTo(68, 152, 64, 132, 62, 108)
      ..lineTo(62, 158)
      ..lineTo(56, 214)
      ..cubicTo(56, 236, 52, 245, 47, 242)
      ..cubicTo(42, 237, 42, 222, 46, 212)
      ..cubicTo(43, 182, 44, 166, 46, 152)
      ..lineTo(42, 108)
      ..cubicTo(40, 92, 43, 78, 53, 74)
      ..cubicTo(66, 69, 82, 66, 89, 61)
      ..lineTo(91, 47)
      ..close();

    return Path.combine(PathOperation.union, p, body);
  }

  static List<Path> _symmetricPaths(Path Function(int s) builder) {
    return [builder(-1), builder(1)];
  }

  static Path _combineSymmetric(Path Function(int s) builder) {
    return Path.combine(PathOperation.union, builder(-1), builder(1));
  }

  static List<_MuscleRegion> _buildFrontRegions() {
    // 1. Trapecios (banda superior cuello -> hombros)
    final trapsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 11.0, 56)
        ..lineTo(100 + s * 13.0, 65)
        ..lineTo(100 + s * 34.0, 74)
        ..lineTo(100 + s * 28.0, 81)
        ..lineTo(100 + s * 10.0, 69)
        ..close(),
    );

    // 2. Hombros (deltoides frontal/lateral)
    final shouldersPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 35.0, 75)
        ..cubicTo(
          100 + s * 49.0,
          75,
          100 + s * 57.0,
          85,
          100 + s * 56.0,
          101,
        )
        ..lineTo(100 + s * 49.0, 109)
        ..cubicTo(
          100 + s * 41.0,
          101,
          100 + s * 38.0,
          91,
          100 + s * 35.0,
          75,
        )
        ..close(),
    );

    // 3. Pecho (pectorales)
    final chestPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 2.5, 84)
        ..cubicTo(
          100 + s * 15.0,
          82,
          100 + s * 28.0,
          82,
          100 + s * 35.0,
          84,
        )
        ..cubicTo(
          100 + s * 38.0,
          96,
          100 + s * 36.0,
          112,
          100 + s * 31.0,
          121,
        )
        ..cubicTo(
          100 + s * 21.0,
          125,
          100 + s * 9.0,
          124,
          100 + s * 2.5,
          120,
        )
        ..close(),
    );

    // 4. Bíceps
    final bicepsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 47.0, 110)
        ..cubicTo(
          100 + s * 55.0,
          118,
          100 + s * 55.0,
          140,
          100 + s * 47.0,
          152,
        )
        ..cubicTo(
          100 + s * 40.0,
          142,
          100 + s * 40.0,
          120,
          100 + s * 47.0,
          110,
        )
        ..close(),
    );

    // 5. Antebrazos
    final forearmsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 47.0, 159)
        ..cubicTo(
          100 + s * 56.0,
          169,
          100 + s * 55.0,
          190,
          100 + s * 52.0,
          210,
        )
        ..lineTo(100 + s * 45.0, 210)
        ..cubicTo(
          100 + s * 40.0,
          188,
          100 + s * 40.0,
          168,
          100 + s * 47.0,
          159,
        )
        ..close(),
    );

    // 6. Core (6 bloques abdominales + oblicuos; hitPath continuo para mejor tacto)
    final coreVisuals = <Path>[
      for (int row = 0; row < 3; row++)
        for (final s in [-1, 1])
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                s == -1 ? 85.0 : 102.0,
                128.0 + row * 18.0,
                13.0,
                14.0,
              ),
              const Radius.circular(3.5),
            ),
          ),
      // Bloque inferior (recto abdominal bajo)
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(88, 182, 24, 16),
          const Radius.circular(6),
        ),
      ),
      // Oblicuos laterales
      ..._symmetricPaths(
        (s) => Path()
          ..moveTo(100 + s * 17.5, 130)
          ..lineTo(100 + s * 28.0, 134)
          ..cubicTo(
            100 + s * 29.0,
            154,
            100 + s * 27.0,
            174,
            100 + s * 25.0,
            190,
          )
          ..lineTo(100 + s * 17.5, 186)
          ..close(),
      ),
    ];
    final coreHit = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(70, 126, 60, 75),
          const Radius.circular(10),
        ),
      );

    // 7. Cuádriceps
    final quadsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 29.0, 210)
        ..cubicTo(
          100 + s * 35.0,
          236,
          100 + s * 32.0,
          270,
          100 + s * 25.0,
          296,
        )
        ..lineTo(100 + s * 11.0, 296)
        ..cubicTo(
          100 + s * 5.0,
          268,
          100 + s * 6.0,
          232,
          100 + s * 14.0,
          212,
        )
        ..close(),
    );

    // 8. Gemelos (vista frontal lateral de la pierna)
    final calvesPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 24.0, 318)
        ..cubicTo(
          100 + s * 30.0,
          334,
          100 + s * 29.0,
          358,
          100 + s * 21.0,
          380,
        )
        ..lineTo(100 + s * 12.0, 380)
        ..cubicTo(
          100 + s * 8.0,
          356,
          100 + s * 9.0,
          334,
          100 + s * 14.0,
          318,
        )
        ..close(),
    );

    return [
      _MuscleRegion(
        key: MuscleGroupKey.chest,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? chestPaths[0] : chestPaths[1],
        ),
        visualPaths: chestPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.shoulders,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? shouldersPaths[0] : shouldersPaths[1],
        ),
        visualPaths: shouldersPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.traps,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? trapsPaths[0] : trapsPaths[1],
        ),
        visualPaths: trapsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.biceps,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? bicepsPaths[0] : bicepsPaths[1],
        ),
        visualPaths: bicepsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.forearms,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? forearmsPaths[0] : forearmsPaths[1],
        ),
        visualPaths: forearmsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.core,
        hitPath: coreHit,
        visualPaths: coreVisuals,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.quadriceps,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? quadsPaths[0] : quadsPaths[1],
        ),
        visualPaths: quadsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.calves,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? calvesPaths[0] : calvesPaths[1],
        ),
        visualPaths: calvesPaths,
      ),
    ];
  }

  static List<_MuscleRegion> _buildBackRegions() {
    // 1. Trapecios (diamante dorsal)
    final trapsPath = Path()
      ..moveTo(100, 56)
      ..lineTo(112, 63)
      ..lineTo(135, 75)
      ..cubicTo(126, 94, 114, 114, 106, 130)
      ..lineTo(100, 134)
      ..lineTo(94, 130)
      ..cubicTo(86, 114, 74, 94, 65, 75)
      ..lineTo(88, 63)
      ..close();

    // 2. Hombros posteriores
    final shouldersPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 35.0, 75)
        ..cubicTo(
          100 + s * 49.0,
          75,
          100 + s * 57.0,
          85,
          100 + s * 56.0,
          101,
        )
        ..lineTo(100 + s * 49.0, 109)
        ..cubicTo(
          100 + s * 41.0,
          101,
          100 + s * 37.0,
          91,
          100 + s * 35.0,
          75,
        )
        ..close(),
    );

    // 3. Espalda / Dorsales
    final backPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 22.0, 96)
        ..lineTo(100 + s * 37.0, 98)
        ..cubicTo(
          100 + s * 37.0,
          122,
          100 + s * 30.0,
          148,
          100 + s * 25.0,
          172,
        )
        ..lineTo(100 + s * 3.0, 172)
        ..lineTo(100 + s * 3.0, 135)
        ..cubicTo(
          100 + s * 10.0,
          124,
          100 + s * 17.0,
          110,
          100 + s * 22.0,
          96,
        )
        ..close(),
    );

    // 4. Tríceps
    final tricepsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 47.0, 109)
        ..cubicTo(
          100 + s * 55.0,
          117,
          100 + s * 55.0,
          139,
          100 + s * 47.0,
          153,
        )
        ..cubicTo(
          100 + s * 40.0,
          141,
          100 + s * 40.0,
          120,
          100 + s * 47.0,
          109,
        )
        ..close(),
    );

    // 5. Antebrazos
    final forearmsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 47.0, 159)
        ..cubicTo(
          100 + s * 56.0,
          169,
          100 + s * 55.0,
          190,
          100 + s * 52.0,
          210,
        )
        ..lineTo(100 + s * 45.0, 210)
        ..cubicTo(
          100 + s * 40.0,
          188,
          100 + s * 40.0,
          168,
          100 + s * 47.0,
          159,
        )
        ..close(),
    );

    // 6. Glúteos
    final glutesPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 3.0, 177)
        ..cubicTo(
          100 + s * 16.0,
          176,
          100 + s * 28.0,
          181,
          100 + s * 32.0,
          196,
        )
        ..cubicTo(
          100 + s * 34.0,
          212,
          100 + s * 28.0,
          224,
          100 + s * 16.0,
          226,
        )
        ..cubicTo(
          100 + s * 8.0,
          226,
          100 + s * 4.0,
          220,
          100 + s * 3.0,
          212,
        )
        ..close(),
    );

    // 7. Femorales / Isquiotibiales
    final hamstringsPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 16.0, 229)
        ..lineTo(100 + s * 30.0, 226)
        ..cubicTo(
          100 + s * 32.0,
          252,
          100 + s * 28.0,
          278,
          100 + s * 24.0,
          296,
        )
        ..lineTo(100 + s * 11.0, 296)
        ..cubicTo(
          100 + s * 6.0,
          270,
          100 + s * 7.0,
          246,
          100 + s * 16.0,
          229,
        )
        ..close(),
    );

    // 8. Gemelos posteriores
    final calvesPaths = _symmetricPaths(
      (s) => Path()
        ..moveTo(100 + s * 24.0, 317)
        ..cubicTo(
          100 + s * 31.0,
          334,
          100 + s * 29.0,
          359,
          100 + s * 21.0,
          378,
        )
        ..lineTo(100 + s * 12.0, 378)
        ..cubicTo(
          100 + s * 8.0,
          356,
          100 + s * 8.0,
          334,
          100 + s * 14.0,
          317,
        )
        ..close(),
    );

    return [
      _MuscleRegion(
        key: MuscleGroupKey.traps,
        hitPath: trapsPath,
        visualPaths: [trapsPath],
      ),
      _MuscleRegion(
        key: MuscleGroupKey.shoulders,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? shouldersPaths[0] : shouldersPaths[1],
        ),
        visualPaths: shouldersPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.back,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? backPaths[0] : backPaths[1],
        ),
        visualPaths: backPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.triceps,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? tricepsPaths[0] : tricepsPaths[1],
        ),
        visualPaths: tricepsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.forearms,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? forearmsPaths[0] : forearmsPaths[1],
        ),
        visualPaths: forearmsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.glutes,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? glutesPaths[0] : glutesPaths[1],
        ),
        visualPaths: glutesPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.hamstrings,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? hamstringsPaths[0] : hamstringsPaths[1],
        ),
        visualPaths: hamstringsPaths,
      ),
      _MuscleRegion(
        key: MuscleGroupKey.calves,
        hitPath: _combineSymmetric(
          (s) => s == -1 ? calvesPaths[0] : calvesPaths[1],
        ),
        visualPaths: calvesPaths,
      ),
    ];
  }
}

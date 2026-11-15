import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/exercise.dart';

/// Patrones biomecánicos de movimiento soportados por la vista animada de ejercicio.
enum MovementPattern {
  horizontalPress,
  inclinePress,
  verticalPress,
  chestFly,
  verticalPull,
  horizontalRow,
  hipHinge,
  squat,
  lunge,
  elbowFlexion,
  elbowExtension,
  lateralRaise,
  coreCrunch,
  calfRaise,
  shrug,
}

/// Especificación completa de un patrón de movimiento para animación e imagen estática.
class _MovementSpec {
  final MovementPose startPose;
  final MovementPose endPose;
  final bool drawBench;
  final bool inclineBench;
  final bool drawHighBar;
  final bool drawBarbell;
  final bool drawFloor;

  String get startLabel => 'Posición inicial';
  String get endLabel => 'Contracción máxima';

  const _MovementSpec({
    required this.startPose,
    required this.endPose,
    this.drawBench = false,
    this.inclineBench = false,
    this.drawHighBar = false,
    this.drawBarbell = false,
    this.drawFloor = true,
  });
}

/// Pose articular normalizada en coordenadas `[0..1]` para interpolación 60fps.
class MovementPose {
  final Offset head;
  final Offset shoulderL;
  final Offset shoulderR;
  final Offset elbowL;
  final Offset elbowR;
  final Offset wristL;
  final Offset wristR;
  final Offset hip;
  final Offset kneeL;
  final Offset kneeR;
  final Offset ankleL;
  final Offset ankleR;
  final Offset hotspot;

  const MovementPose({
    required this.head,
    required this.shoulderL,
    required this.shoulderR,
    required this.elbowL,
    required this.elbowR,
    required this.wristL,
    required this.wristR,
    required this.hip,
    required this.kneeL,
    required this.kneeR,
    required this.ankleL,
    required this.ankleR,
    required this.hotspot,
  });

  static MovementPose lerp(MovementPose a, MovementPose b, double t) {
    return MovementPose(
      head: Offset.lerp(a.head, b.head, t)!,
      shoulderL: Offset.lerp(a.shoulderL, b.shoulderL, t)!,
      shoulderR: Offset.lerp(a.shoulderR, b.shoulderR, t)!,
      elbowL: Offset.lerp(a.elbowL, b.elbowL, t)!,
      elbowR: Offset.lerp(a.elbowR, b.elbowR, t)!,
      wristL: Offset.lerp(a.wristL, b.wristL, t)!,
      wristR: Offset.lerp(a.wristR, b.wristR, t)!,
      hip: Offset.lerp(a.hip, b.hip, t)!,
      kneeL: Offset.lerp(a.kneeL, b.kneeL, t)!,
      kneeR: Offset.lerp(a.kneeR, b.kneeR, t)!,
      ankleL: Offset.lerp(a.ankleL, b.ankleL, t)!,
      ankleR: Offset.lerp(a.ankleR, b.ankleR, t)!,
      hotspot: Offset.lerp(a.hotspot, b.hotspot, t)!,
    );
  }
}

/// Clasifica el patrón de movimiento y color de acento a partir del ejercicio.
class _ExerciseVisualProfile {
  static MovementPattern classifyPattern(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    final muscle = (exercise.primaryMuscle ?? '').toLowerCase();

    for (final rule in _patternRules) {
      if (rule.keywords.any(name.contains)) {
        return rule.pattern;
      }
    }

    return _muscleFallbackPatterns[muscle] ?? MovementPattern.squat;
  }

  static Color accentColorFor(Exercise exercise) {
    final muscle = (exercise.primaryMuscle ?? '').trim().toLowerCase();
    return _muscleColors[muscle] ?? Colors.blueAccent;
  }

  static _MovementSpec specFor(MovementPattern pattern) => _specs[pattern]!;

  static const Map<String, Color> _muscleColors = {
    'chest': Colors.blueAccent,
    'back': Color(0xFF7C4DFF),
    'quadriceps': Color(0xFF00BFA5),
    'hamstrings': Color(0xFF26A69A),
    'glutes': Color(0xFF00ACC1),
    'calves': Color(0xFF4DB6AC),
    'shoulders': Color(0xFFFFB300),
    'traps': Color(0xFFFF8F00),
    'biceps': Color(0xFF29B6F6),
    'triceps': Color(0xFFEC407A),
    'forearms': Color(0xFFAB47BC),
    'core': Color(0xFF66BB6A),
  };

  static const Map<String, MovementPattern> _muscleFallbackPatterns = {
    'chest': MovementPattern.horizontalPress,
    'back': MovementPattern.horizontalRow,
    'quadriceps': MovementPattern.squat,
    'hamstrings': MovementPattern.hipHinge,
    'glutes': MovementPattern.hipHinge,
    'calves': MovementPattern.calfRaise,
    'shoulders': MovementPattern.verticalPress,
    'traps': MovementPattern.shrug,
    'biceps': MovementPattern.elbowFlexion,
    'triceps': MovementPattern.elbowExtension,
    'forearms': MovementPattern.elbowFlexion,
    'core': MovementPattern.coreCrunch,
  };

  static final List<_PatternRule> _patternRules = [
    _PatternRule(MovementPattern.inclinePress, ['incline']),
    _PatternRule(MovementPattern.chestFly, ['fly', 'crossover', 'pec deck']),
    _PatternRule(MovementPattern.horizontalPress, [
      'bench press',
      'chest press',
      'push-up',
      'chest dip',
    ]),
    _PatternRule(MovementPattern.verticalPress, [
      'overhead press',
      'shoulder press',
      'arnold press',
      'push press',
    ]),
    _PatternRule(MovementPattern.verticalPull, [
      'pull-up',
      'chin-up',
      'pulldown',
    ]),
    _PatternRule(MovementPattern.shrug, ['shrug', 'upright row', 'farmer']),
    _PatternRule(MovementPattern.horizontalRow, ['row', 'face pull']),
    _PatternRule(MovementPattern.calfRaise, ['calf']),
    _PatternRule(MovementPattern.lunge, ['lunge', 'split squat', 'step-up']),
    _PatternRule(MovementPattern.hipHinge, [
      'deadlift',
      'hip thrust',
      'glute bridge',
      'back extension',
      'good morning',
      'pull-through',
      'rack pull',
      'swing',
      'leg curl',
      'kickback',
      'abduction',
      'adduction',
    ]),
    _PatternRule(MovementPattern.squat, ['squat', 'leg press', 'leg extension']),
    _PatternRule(MovementPattern.elbowExtension, [
      'tricep',
      'pushdown',
      'skull crusher',
      'dip',
    ]),
    _PatternRule(MovementPattern.elbowFlexion, ['curl']),
    _PatternRule(MovementPattern.lateralRaise, ['lateral raise', 'front raise']),
    _PatternRule(MovementPattern.coreCrunch, [
      'plank',
      'crunch',
      'leg raise',
      'knee raise',
      'rollout',
      'twist',
      'dead bug',
      'woodchopper',
    ]),
  ];

  static const Map<MovementPattern, _MovementSpec> _specs = {
    MovementPattern.horizontalPress: _MovementSpec(
      drawBench: true,
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.24, 0.56),
        shoulderL: Offset(0.36, 0.57),
        shoulderR: Offset(0.36, 0.62),
        elbowL: Offset(0.34, 0.48),
        elbowR: Offset(0.38, 0.52),
        wristL: Offset(0.35, 0.44),
        wristR: Offset(0.37, 0.44),
        hip: Offset(0.62, 0.62),
        kneeL: Offset(0.76, 0.64),
        kneeR: Offset(0.78, 0.66),
        ankleL: Offset(0.77, 0.85),
        ankleR: Offset(0.79, 0.85),
        hotspot: Offset(0.38, 0.57),
      ),
      endPose: MovementPose(
        head: Offset(0.24, 0.56),
        shoulderL: Offset(0.36, 0.57),
        shoulderR: Offset(0.36, 0.62),
        elbowL: Offset(0.35, 0.37),
        elbowR: Offset(0.37, 0.38),
        wristL: Offset(0.35, 0.20),
        wristR: Offset(0.37, 0.20),
        hip: Offset(0.62, 0.62),
        kneeL: Offset(0.76, 0.64),
        kneeR: Offset(0.78, 0.66),
        ankleL: Offset(0.77, 0.85),
        ankleR: Offset(0.79, 0.85),
        hotspot: Offset(0.38, 0.57),
      ),
    ),
    MovementPattern.inclinePress: _MovementSpec(
      drawBench: true,
      inclineBench: true,
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.30, 0.36),
        shoulderL: Offset(0.38, 0.46),
        shoulderR: Offset(0.40, 0.49),
        elbowL: Offset(0.34, 0.54),
        elbowR: Offset(0.42, 0.56),
        wristL: Offset(0.41, 0.38),
        wristR: Offset(0.44, 0.39),
        hip: Offset(0.58, 0.68),
        kneeL: Offset(0.74, 0.68),
        kneeR: Offset(0.76, 0.70),
        ankleL: Offset(0.76, 0.85),
        ankleR: Offset(0.78, 0.85),
        hotspot: Offset(0.40, 0.47),
      ),
      endPose: MovementPose(
        head: Offset(0.30, 0.36),
        shoulderL: Offset(0.38, 0.46),
        shoulderR: Offset(0.40, 0.49),
        elbowL: Offset(0.41, 0.30),
        elbowR: Offset(0.44, 0.31),
        wristL: Offset(0.43, 0.16),
        wristR: Offset(0.46, 0.16),
        hip: Offset(0.58, 0.68),
        kneeL: Offset(0.74, 0.68),
        kneeR: Offset(0.76, 0.70),
        ankleL: Offset(0.76, 0.85),
        ankleR: Offset(0.78, 0.85),
        hotspot: Offset(0.40, 0.47),
      ),
    ),
    MovementPattern.verticalPress: _MovementSpec(
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.50, 0.23),
        shoulderL: Offset(0.42, 0.34),
        shoulderR: Offset(0.58, 0.34),
        elbowL: Offset(0.33, 0.42),
        elbowR: Offset(0.67, 0.42),
        wristL: Offset(0.36, 0.31),
        wristR: Offset(0.64, 0.31),
        hip: Offset(0.50, 0.55),
        kneeL: Offset(0.44, 0.71),
        kneeR: Offset(0.56, 0.71),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.42, 0.34),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.23),
        shoulderL: Offset(0.42, 0.34),
        shoulderR: Offset(0.58, 0.34),
        elbowL: Offset(0.40, 0.22),
        elbowR: Offset(0.60, 0.22),
        wristL: Offset(0.40, 0.11),
        wristR: Offset(0.60, 0.11),
        hip: Offset(0.50, 0.55),
        kneeL: Offset(0.44, 0.71),
        kneeR: Offset(0.56, 0.71),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.58, 0.34),
      ),
    ),
    MovementPattern.chestFly: _MovementSpec(
      startPose: MovementPose(
        head: Offset(0.50, 0.23),
        shoulderL: Offset(0.42, 0.34),
        shoulderR: Offset(0.58, 0.34),
        elbowL: Offset(0.24, 0.38),
        elbowR: Offset(0.76, 0.38),
        wristL: Offset(0.18, 0.42),
        wristR: Offset(0.82, 0.42),
        hip: Offset(0.50, 0.56),
        kneeL: Offset(0.44, 0.71),
        kneeR: Offset(0.56, 0.71),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.50, 0.37),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.23),
        shoulderL: Offset(0.42, 0.34),
        shoulderR: Offset(0.58, 0.34),
        elbowL: Offset(0.39, 0.41),
        elbowR: Offset(0.61, 0.41),
        wristL: Offset(0.47, 0.40),
        wristR: Offset(0.53, 0.40),
        hip: Offset(0.50, 0.56),
        kneeL: Offset(0.44, 0.71),
        kneeR: Offset(0.56, 0.71),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.50, 0.37),
      ),
    ),
    MovementPattern.verticalPull: _MovementSpec(
      drawHighBar: true,
      drawFloor: false,
      startPose: MovementPose(
        head: Offset(0.50, 0.37),
        shoulderL: Offset(0.42, 0.44),
        shoulderR: Offset(0.58, 0.44),
        elbowL: Offset(0.36, 0.29),
        elbowR: Offset(0.64, 0.29),
        wristL: Offset(0.34, 0.14),
        wristR: Offset(0.66, 0.14),
        hip: Offset(0.50, 0.64),
        kneeL: Offset(0.46, 0.78),
        kneeR: Offset(0.54, 0.78),
        ankleL: Offset(0.46, 0.89),
        ankleR: Offset(0.54, 0.89),
        hotspot: Offset(0.44, 0.50),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.21),
        shoulderL: Offset(0.41, 0.30),
        shoulderR: Offset(0.59, 0.30),
        elbowL: Offset(0.34, 0.42),
        elbowR: Offset(0.66, 0.42),
        wristL: Offset(0.34, 0.14),
        wristR: Offset(0.66, 0.14),
        hip: Offset(0.50, 0.50),
        kneeL: Offset(0.46, 0.65),
        kneeR: Offset(0.54, 0.65),
        ankleL: Offset(0.46, 0.77),
        ankleR: Offset(0.54, 0.77),
        hotspot: Offset(0.56, 0.38),
      ),
    ),
    MovementPattern.horizontalRow: _MovementSpec(
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.31, 0.35),
        shoulderL: Offset(0.39, 0.40),
        shoulderR: Offset(0.41, 0.43),
        elbowL: Offset(0.38, 0.56),
        elbowR: Offset(0.40, 0.58),
        wristL: Offset(0.37, 0.71),
        wristR: Offset(0.39, 0.71),
        hip: Offset(0.60, 0.51),
        kneeL: Offset(0.57, 0.69),
        kneeR: Offset(0.60, 0.70),
        ankleL: Offset(0.58, 0.86),
        ankleR: Offset(0.61, 0.86),
        hotspot: Offset(0.49, 0.44),
      ),
      endPose: MovementPose(
        head: Offset(0.31, 0.35),
        shoulderL: Offset(0.39, 0.40),
        shoulderR: Offset(0.41, 0.43),
        elbowL: Offset(0.49, 0.33),
        elbowR: Offset(0.51, 0.35),
        wristL: Offset(0.46, 0.49),
        wristR: Offset(0.48, 0.49),
        hip: Offset(0.60, 0.51),
        kneeL: Offset(0.57, 0.69),
        kneeR: Offset(0.60, 0.70),
        ankleL: Offset(0.58, 0.86),
        ankleR: Offset(0.61, 0.86),
        hotspot: Offset(0.49, 0.44),
      ),
    ),
    MovementPattern.hipHinge: _MovementSpec(
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.28, 0.42),
        shoulderL: Offset(0.37, 0.47),
        shoulderR: Offset(0.39, 0.49),
        elbowL: Offset(0.37, 0.61),
        elbowR: Offset(0.39, 0.62),
        wristL: Offset(0.38, 0.75),
        wristR: Offset(0.40, 0.75),
        hip: Offset(0.63, 0.52),
        kneeL: Offset(0.54, 0.69),
        kneeR: Offset(0.57, 0.70),
        ankleL: Offset(0.56, 0.86),
        ankleR: Offset(0.59, 0.86),
        hotspot: Offset(0.60, 0.54),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.19),
        shoulderL: Offset(0.48, 0.29),
        shoulderR: Offset(0.52, 0.29),
        elbowL: Offset(0.46, 0.43),
        elbowR: Offset(0.50, 0.43),
        wristL: Offset(0.45, 0.57),
        wristR: Offset(0.49, 0.57),
        hip: Offset(0.51, 0.53),
        kneeL: Offset(0.51, 0.70),
        kneeR: Offset(0.54, 0.70),
        ankleL: Offset(0.52, 0.86),
        ankleR: Offset(0.55, 0.86),
        hotspot: Offset(0.54, 0.57),
      ),
    ),
    MovementPattern.squat: _MovementSpec(
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.50, 0.18),
        shoulderL: Offset(0.43, 0.28),
        shoulderR: Offset(0.57, 0.28),
        elbowL: Offset(0.34, 0.34),
        elbowR: Offset(0.66, 0.34),
        wristL: Offset(0.36, 0.25),
        wristR: Offset(0.64, 0.25),
        hip: Offset(0.50, 0.52),
        kneeL: Offset(0.44, 0.69),
        kneeR: Offset(0.56, 0.69),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.46, 0.62),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.38),
        shoulderL: Offset(0.43, 0.48),
        shoulderR: Offset(0.57, 0.48),
        elbowL: Offset(0.34, 0.53),
        elbowR: Offset(0.66, 0.53),
        wristL: Offset(0.36, 0.45),
        wristR: Offset(0.64, 0.45),
        hip: Offset(0.50, 0.69),
        kneeL: Offset(0.36, 0.67),
        kneeR: Offset(0.64, 0.67),
        ankleL: Offset(0.43, 0.86),
        ankleR: Offset(0.57, 0.86),
        hotspot: Offset(0.54, 0.66),
      ),
    ),
    MovementPattern.lunge: _MovementSpec(
      startPose: MovementPose(
        head: Offset(0.48, 0.18),
        shoulderL: Offset(0.45, 0.29),
        shoulderR: Offset(0.51, 0.29),
        elbowL: Offset(0.43, 0.42),
        elbowR: Offset(0.53, 0.42),
        wristL: Offset(0.43, 0.54),
        wristR: Offset(0.53, 0.54),
        hip: Offset(0.48, 0.51),
        kneeL: Offset(0.37, 0.69),
        kneeR: Offset(0.61, 0.70),
        ankleL: Offset(0.34, 0.86),
        ankleR: Offset(0.65, 0.86),
        hotspot: Offset(0.40, 0.63),
      ),
      endPose: MovementPose(
        head: Offset(0.48, 0.33),
        shoulderL: Offset(0.45, 0.44),
        shoulderR: Offset(0.51, 0.44),
        elbowL: Offset(0.43, 0.56),
        elbowR: Offset(0.53, 0.56),
        wristL: Offset(0.43, 0.67),
        wristR: Offset(0.53, 0.67),
        hip: Offset(0.48, 0.65),
        kneeL: Offset(0.32, 0.66),
        kneeR: Offset(0.59, 0.82),
        ankleL: Offset(0.32, 0.86),
        ankleR: Offset(0.70, 0.86),
        hotspot: Offset(0.36, 0.67),
      ),
    ),
    MovementPattern.elbowFlexion: _MovementSpec(
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.50, 0.19),
        shoulderL: Offset(0.42, 0.30),
        shoulderR: Offset(0.58, 0.30),
        elbowL: Offset(0.40, 0.46),
        elbowR: Offset(0.60, 0.46),
        wristL: Offset(0.39, 0.62),
        wristR: Offset(0.61, 0.62),
        hip: Offset(0.50, 0.54),
        kneeL: Offset(0.44, 0.70),
        kneeR: Offset(0.56, 0.70),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.40, 0.39),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.19),
        shoulderL: Offset(0.42, 0.30),
        shoulderR: Offset(0.58, 0.30),
        elbowL: Offset(0.40, 0.46),
        elbowR: Offset(0.60, 0.46),
        wristL: Offset(0.41, 0.32),
        wristR: Offset(0.59, 0.32),
        hip: Offset(0.50, 0.54),
        kneeL: Offset(0.44, 0.70),
        kneeR: Offset(0.56, 0.70),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.60, 0.39),
      ),
    ),
    MovementPattern.elbowExtension: _MovementSpec(
      startPose: MovementPose(
        head: Offset(0.48, 0.21),
        shoulderL: Offset(0.45, 0.32),
        shoulderR: Offset(0.51, 0.32),
        elbowL: Offset(0.44, 0.46),
        elbowR: Offset(0.48, 0.46),
        wristL: Offset(0.32, 0.38),
        wristR: Offset(0.35, 0.38),
        hip: Offset(0.52, 0.55),
        kneeL: Offset(0.49, 0.71),
        kneeR: Offset(0.55, 0.71),
        ankleL: Offset(0.49, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.46, 0.39),
      ),
      endPose: MovementPose(
        head: Offset(0.48, 0.21),
        shoulderL: Offset(0.45, 0.32),
        shoulderR: Offset(0.51, 0.32),
        elbowL: Offset(0.44, 0.46),
        elbowR: Offset(0.48, 0.46),
        wristL: Offset(0.40, 0.64),
        wristR: Offset(0.44, 0.64),
        hip: Offset(0.52, 0.55),
        kneeL: Offset(0.49, 0.71),
        kneeR: Offset(0.55, 0.71),
        ankleL: Offset(0.49, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.46, 0.39),
      ),
    ),
    MovementPattern.lateralRaise: _MovementSpec(
      startPose: MovementPose(
        head: Offset(0.50, 0.20),
        shoulderL: Offset(0.42, 0.31),
        shoulderR: Offset(0.58, 0.31),
        elbowL: Offset(0.38, 0.45),
        elbowR: Offset(0.62, 0.45),
        wristL: Offset(0.36, 0.59),
        wristR: Offset(0.64, 0.59),
        hip: Offset(0.50, 0.54),
        kneeL: Offset(0.44, 0.70),
        kneeR: Offset(0.56, 0.70),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.42, 0.31),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.20),
        shoulderL: Offset(0.42, 0.31),
        shoulderR: Offset(0.58, 0.31),
        elbowL: Offset(0.28, 0.31),
        elbowR: Offset(0.72, 0.31),
        wristL: Offset(0.16, 0.31),
        wristR: Offset(0.84, 0.31),
        hip: Offset(0.50, 0.54),
        kneeL: Offset(0.44, 0.70),
        kneeR: Offset(0.56, 0.70),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.58, 0.31),
      ),
    ),
    MovementPattern.coreCrunch: _MovementSpec(
      startPose: MovementPose(
        head: Offset(0.22, 0.76),
        shoulderL: Offset(0.32, 0.78),
        shoulderR: Offset(0.32, 0.81),
        elbowL: Offset(0.28, 0.69),
        elbowR: Offset(0.30, 0.70),
        wristL: Offset(0.23, 0.72),
        wristR: Offset(0.24, 0.73),
        hip: Offset(0.54, 0.81),
        kneeL: Offset(0.67, 0.67),
        kneeR: Offset(0.69, 0.68),
        ankleL: Offset(0.77, 0.84),
        ankleR: Offset(0.79, 0.84),
        hotspot: Offset(0.43, 0.79),
      ),
      endPose: MovementPose(
        head: Offset(0.38, 0.56),
        shoulderL: Offset(0.41, 0.65),
        shoulderR: Offset(0.42, 0.67),
        elbowL: Offset(0.47, 0.58),
        elbowR: Offset(0.49, 0.59),
        wristL: Offset(0.41, 0.55),
        wristR: Offset(0.43, 0.56),
        hip: Offset(0.55, 0.80),
        kneeL: Offset(0.66, 0.66),
        kneeR: Offset(0.68, 0.67),
        ankleL: Offset(0.76, 0.84),
        ankleR: Offset(0.78, 0.84),
        hotspot: Offset(0.47, 0.74),
      ),
    ),
    MovementPattern.calfRaise: _MovementSpec(
      startPose: MovementPose(
        head: Offset(0.50, 0.21),
        shoulderL: Offset(0.43, 0.32),
        shoulderR: Offset(0.57, 0.32),
        elbowL: Offset(0.40, 0.46),
        elbowR: Offset(0.60, 0.46),
        wristL: Offset(0.39, 0.59),
        wristR: Offset(0.61, 0.59),
        hip: Offset(0.50, 0.55),
        kneeL: Offset(0.45, 0.71),
        kneeR: Offset(0.55, 0.71),
        ankleL: Offset(0.45, 0.86),
        ankleR: Offset(0.55, 0.86),
        hotspot: Offset(0.45, 0.78),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.14),
        shoulderL: Offset(0.43, 0.25),
        shoulderR: Offset(0.57, 0.25),
        elbowL: Offset(0.40, 0.39),
        elbowR: Offset(0.60, 0.39),
        wristL: Offset(0.39, 0.52),
        wristR: Offset(0.61, 0.52),
        hip: Offset(0.50, 0.48),
        kneeL: Offset(0.45, 0.64),
        kneeR: Offset(0.55, 0.64),
        ankleL: Offset(0.45, 0.79),
        ankleR: Offset(0.55, 0.79),
        hotspot: Offset(0.55, 0.72),
      ),
    ),
    MovementPattern.shrug: _MovementSpec(
      drawBarbell: true,
      startPose: MovementPose(
        head: Offset(0.50, 0.19),
        shoulderL: Offset(0.41, 0.32),
        shoulderR: Offset(0.59, 0.32),
        elbowL: Offset(0.39, 0.46),
        elbowR: Offset(0.61, 0.46),
        wristL: Offset(0.39, 0.59),
        wristR: Offset(0.61, 0.59),
        hip: Offset(0.50, 0.54),
        kneeL: Offset(0.44, 0.70),
        kneeR: Offset(0.56, 0.70),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.46, 0.29),
      ),
      endPose: MovementPose(
        head: Offset(0.50, 0.19),
        shoulderL: Offset(0.42, 0.26),
        shoulderR: Offset(0.58, 0.26),
        elbowL: Offset(0.39, 0.40),
        elbowR: Offset(0.61, 0.40),
        wristL: Offset(0.39, 0.53),
        wristR: Offset(0.61, 0.53),
        hip: Offset(0.50, 0.54),
        kneeL: Offset(0.44, 0.70),
        kneeR: Offset(0.56, 0.70),
        ankleL: Offset(0.44, 0.86),
        ankleR: Offset(0.56, 0.86),
        hotspot: Offset(0.54, 0.25),
      ),
    ),
  };
}

class _PatternRule {
  final MovementPattern pattern;
  final List<String> keywords;
  const _PatternRule(this.pattern, this.keywords);
}

/// Miniatura compacta de ejercicio para tarjetas y listas, con distintivo `GIF`.
class ExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;
  final double size;
  final VoidCallback? onTap;

  const ExerciseThumbnail({
    super.key,
    required this.exercise,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _ExerciseVisualProfile.accentColorFor(exercise);
    final pattern = _ExerciseVisualProfile.classifyPattern(exercise);
    final spec = _ExerciseVisualProfile.specFor(pattern);
    final hasImage =
        exercise.imageUrl != null && exercise.imageUrl!.trim().isNotEmpty;

    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              exercise.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackPainter(spec, accent),
            )
          else
            _buildFallbackPainter(spec, accent),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: accent.withValues(alpha: 0.65),
                  width: 0.6,
                ),
              ),
              child: Text(
                'GIF',
                style: TextStyle(
                  color: accent,
                  fontSize: size >= 44 ? 8.5 : 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildFallbackPainter(_MovementSpec spec, Color accent) {
    return CustomPaint(
      painter: _ExerciseBiomechanicsPainter(
        spec: spec,
        progress: 0.55,
        accentColor: accent,
        showOverlayGuides: false,
      ),
    );
  }
}

/// Reproductor interactivo de demostración visual:
/// alterna entre animación en movimiento tipo GIF y vista comparativa de imagen/músculos.
class ExerciseMovementPlayer extends StatefulWidget {
  final Exercise exercise;

  const ExerciseMovementPlayer({super.key, required this.exercise});

  @override
  State<ExerciseMovementPlayer> createState() => _ExerciseMovementPlayerState();
}

class _ExerciseMovementPlayerState extends State<ExerciseMovementPlayer>
    with SingleTickerProviderStateMixin {
  static const List<double> _speedOptions = [0.5, 1.0, 1.5];

  late final AnimationController _controller;
  late final MovementPattern _pattern;
  late final _MovementSpec _spec;
  late final Color _accent;

  bool _isPlaying = true;
  double _speed = 1.0;
  int _selectedTab = 0; // 0 = Movimiento (GIF), 1 = Imagen / Músculos
  bool _preferRealPhotos = true;

  bool get _hasNetworkSequence =>
      _isNonEmpty(widget.exercise.imageUrl) &&
      _isNonEmpty(widget.exercise.animationUrl);

  @override
  void initState() {
    super.initState();
    _pattern = _ExerciseVisualProfile.classifyPattern(widget.exercise);
    _spec = _ExerciseVisualProfile.specFor(_pattern);
    _accent = _ExerciseVisualProfile.accentColorFor(widget.exercise);
    _preferRealPhotos = _hasNetworkSequence;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isNonEmpty(String? value) => value != null && value.trim().isNotEmpty;

  void _togglePlayback() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _cycleSpeed() {
    final nextIndex = (_speedOptions.indexOf(_speed) + 1) % _speedOptions.length;
    final nextSpeed = _speedOptions[nextIndex];
    final currentVal = _controller.value;

    setState(() => _speed = nextSpeed);
    _controller.duration = Duration(
      milliseconds: (1600 / nextSpeed).round(),
    );
    _controller.value = currentVal;
    if (_isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14161B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeBar(),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: _selectedTab == 0
                ? _buildAnimatedMovementView()
                : _buildStaticComparisonView(),
          ),
          if (_selectedTab == 0) _buildPlaybackControls(),
        ],
      ),
    );
  }

  Widget _buildModeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      color: const Color(0xFF1A1D24),
      child: Row(
        children: [
          Expanded(
            child: _ModeTabButton(
              icon: Icons.play_circle_outline_rounded,
              label: 'Movimiento (GIF)',
              selected: _selectedTab == 0,
              accent: _accent,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeTabButton(
              icon: Icons.image_outlined,
              label: 'Imagen / Postura',
              selected: _selectedTab == 1,
              accent: _accent,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMovementView() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final eased = Curves.easeInOut.transform(_controller.value);
        final isConcentric = _controller.status != AnimationStatus.reverse;
        final phaseLabel = isConcentric
            ? 'Fase concéntrica'
            : 'Fase excéntrica';

        return Stack(
          fit: StackFit.expand,
          children: [
            if (_hasNetworkSequence && _preferRealPhotos)
              _NetworkGifSequenceView(
                startUrl: widget.exercise.imageUrl!,
                endUrl: widget.exercise.animationUrl!,
                showEndFrame: eased >= 0.5,
                fallbackBuilder: () => _buildBiomechanicsCanvas(eased),
              )
            else
              _buildBiomechanicsCanvas(eased),
            Positioned(
              left: 10,
              top: 10,
              child: _OverlayPill(
                icon: isConcentric
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                text: phaseLabel,
                color: _accent,
              ),
            ),
            if (_hasNetworkSequence)
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _preferRealPhotos = !_preferRealPhotos),
                  child: _OverlayPill(
                    icon: _preferRealPhotos
                        ? Icons.accessibility_new_rounded
                        : Icons.photo_library_outlined,
                    text: _preferRealPhotos ? 'Ver esquema' : 'Ver fotos',
                    color: Colors.white70,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: eased,
                minHeight: 3,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBiomechanicsCanvas(double progress) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [_accent.withValues(alpha: 0.14), const Color(0xFF101216)],
        ),
      ),
      child: CustomPaint(
        painter: _ExerciseBiomechanicsPainter(
          spec: _spec,
          progress: progress,
          accentColor: _accent,
          showOverlayGuides: true,
        ),
      ),
    );
  }

  Widget _buildStaticComparisonView() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: _PostureSnapshotCard(
              title: '1. ${_spec.startLabel}',
              imageUrl: widget.exercise.imageUrl,
              spec: _spec,
              progress: 0.0,
              accent: _accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PostureSnapshotCard(
              title: '2. ${_spec.endLabel}',
              imageUrl: widget.exercise.animationUrl ?? widget.exercise.imageUrl,
              spec: _spec,
              progress: 1.0,
              accent: _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final speedLabel = _speed == 1.0 ? '1x' : '${_speed}x';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1A1D24),
      child: Row(
        children: [
          InkWell(
            onTap: _togglePlayback,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _accent,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPlaying ? 'Pausar' : 'Reproducir',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Velocidad:',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _cycleSpeed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF262A34),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                speedLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alterna sin parpadeo dos URLs (`imageUrl` y `animationUrl`) ya montadas en pila.
class _NetworkGifSequenceView extends StatefulWidget {
  final String startUrl;
  final String endUrl;
  final bool showEndFrame;
  final Widget Function() fallbackBuilder;

  const _NetworkGifSequenceView({
    required this.startUrl,
    required this.endUrl,
    required this.showEndFrame,
    required this.fallbackBuilder,
  });

  @override
  State<_NetworkGifSequenceView> createState() =>
      _NetworkGifSequenceViewState();
}

class _NetworkGifSequenceViewState extends State<_NetworkGifSequenceView> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) return widget.fallbackBuilder();

    return Container(
      color: const Color(0xFF0E1014),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.startUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return widget.fallbackBuilder();
            },
            errorBuilder: (_, _, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasError) setState(() => _hasError = true);
              });
              return widget.fallbackBuilder();
            },
          ),
          Opacity(
            opacity: widget.showEndFrame ? 1.0 : 0.0,
            child: Image.network(
              widget.endUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostureSnapshotCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final _MovementSpec spec;
  final double progress;
  final Color accent;

  const _PostureSnapshotCard({
    required this.title,
    required this.imageUrl,
    required this.spec,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1014),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: hasUrl
                ? Image.network(
                    imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildVectorFallback(),
                  )
                : _buildVectorFallback(),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            color: const Color(0xFF1A1D24),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[200],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorFallback() {
    return CustomPaint(
      size: Size.infinite,
      painter: _ExerciseBiomechanicsPainter(
        spec: spec,
        progress: progress,
        accentColor: accent,
        showOverlayGuides: false,
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.2)
              : const Color(0xFF252830),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? accent : Colors.grey[400]),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _OverlayPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter vectorial reutilizable que dibuja aparato, articulaciones, trayectoria y foco muscular.
class _ExerciseBiomechanicsPainter extends CustomPainter {
  final _MovementSpec spec;
  final double progress;
  final Color accentColor;
  final bool showOverlayGuides;

  const _ExerciseBiomechanicsPainter({
    required this.spec,
    required this.progress,
    required this.accentColor,
    required this.showOverlayGuides,
  });

  Offset _pt(Offset norm, Size size) =>
      Offset(norm.dx * size.width, norm.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = MovementPose.lerp(spec.startPose, spec.endPose, progress);
    _drawApparatus(canvas, size, pose);
    if (showOverlayGuides) {
      _drawTrajectoryGuide(canvas, size);
    }
    _drawMusclePulse(canvas, size, pose.hotspot);
    _drawBody(canvas, size, pose);
  }

  void _drawApparatus(Canvas canvas, Size size, MovementPose pose) {
    final structPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = size.shortestSide * 0.025
      ..strokeCap = StrokeCap.round;

    if (spec.drawFloor) {
      final y = size.height * 0.87;
      canvas.drawLine(Offset(size.width * 0.12, y), Offset(size.width * 0.88, y), structPaint);
    }

    if (spec.drawBench) {
      if (spec.inclineBench) {
        canvas.drawLine(_pt(const Offset(0.28, 0.42), size), _pt(const Offset(0.58, 0.72), size), structPaint);
        canvas.drawLine(_pt(const Offset(0.58, 0.72), size), _pt(const Offset(0.75, 0.72), size), structPaint);
        canvas.drawLine(_pt(const Offset(0.36, 0.50), size), _pt(const Offset(0.36, 0.87), size), structPaint);
        canvas.drawLine(_pt(const Offset(0.68, 0.72), size), _pt(const Offset(0.68, 0.87), size), structPaint);
      } else {
        canvas.drawLine(_pt(const Offset(0.22, 0.64), size), _pt(const Offset(0.72, 0.64), size), structPaint);
        canvas.drawLine(_pt(const Offset(0.29, 0.64), size), _pt(const Offset(0.29, 0.87), size), structPaint);
        canvas.drawLine(_pt(const Offset(0.66, 0.64), size), _pt(const Offset(0.66, 0.87), size), structPaint);
      }
    }

    if (spec.drawHighBar) {
      canvas.drawLine(_pt(const Offset(0.22, 0.13), size), _pt(const Offset(0.78, 0.13), size), structPaint);
    }

    if (spec.drawBarbell) {
      final wL = _pt(pose.wristL, size);
      final wR = _pt(pose.wristR, size);
      final mid = Offset((wL.dx + wR.dx) / 2, (wL.dy + wR.dy) / 2);
      final span = math.max((wR.dx - wL.dx).abs() * 0.8 + size.width * 0.14, size.width * 0.22);
      final barStart = Offset(mid.dx - span / 2, mid.dy);
      final barEnd = Offset(mid.dx + span / 2, mid.dy);

      final barPaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = size.shortestSide * 0.022
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(barStart, barEnd, barPaint);

      final platePaint = Paint()
        ..color = accentColor
        ..strokeWidth = size.shortestSide * 0.042
        ..strokeCap = StrokeCap.round;
      final plateHalfH = size.shortestSide * 0.075;
      canvas.drawLine(
        Offset(barStart.dx + 4, barStart.dy - plateHalfH),
        Offset(barStart.dx + 4, barStart.dy + plateHalfH),
        platePaint,
      );
      canvas.drawLine(
        Offset(barEnd.dx - 4, barEnd.dy - plateHalfH),
        Offset(barEnd.dx - 4, barEnd.dy + plateHalfH),
        platePaint,
      );
    }
  }

  void _drawTrajectoryGuide(Canvas canvas, Size size) {
    final startMid = Offset(
      (spec.startPose.wristL.dx + spec.startPose.wristR.dx) / 2,
      (spec.startPose.wristL.dy + spec.startPose.wristR.dy) / 2,
    );
    final endMid = Offset(
      (spec.endPose.wristL.dx + spec.endPose.wristR.dx) / 2,
      (spec.endPose.wristL.dy + spec.endPose.wristR.dy) / 2,
    );
    final p1 = _pt(startMid, size);
    final p2 = _pt(endMid, size);
    if ((p2 - p1).distance < 8) return;

    final guidePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, guidePaint);
    canvas.drawCircle(p1, 3.5, Paint()..color = Colors.white38);
    canvas.drawCircle(p2, 4.0, Paint()..color = accentColor);
  }

  void _drawMusclePulse(Canvas canvas, Size size, Offset normHotspot) {
    final center = _pt(normHotspot, size);
    final baseR = size.shortestSide * (0.09 + 0.05 * progress);
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.22 + 0.28 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, baseR, glowPaint);
  }

  void _drawBody(Canvas canvas, Size size, MovementPose pose) {
    final limbStroke = math.max(size.shortestSide * 0.036, 2.2);
    final torsoStroke = math.max(size.shortestSide * 0.05, 3.0);

    final backLimbPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..strokeWidth = limbStroke
      ..strokeCap = StrokeCap.round;

    final frontLimbPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = limbStroke
      ..strokeCap = StrokeCap.round;

    final torsoPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..strokeWidth = torsoStroke
      ..strokeCap = StrokeCap.round;

    final shoulderMid = Offset(
      (pose.shoulderL.dx + pose.shoulderR.dx) / 2,
      (pose.shoulderL.dy + pose.shoulderR.dy) / 2,
    );

    // Back limbs
    canvas.drawLine(_pt(pose.hip, size), _pt(pose.kneeL, size), backLimbPaint);
    canvas.drawLine(_pt(pose.kneeL, size), _pt(pose.ankleL, size), backLimbPaint);
    canvas.drawLine(_pt(pose.shoulderL, size), _pt(pose.elbowL, size), backLimbPaint);
    canvas.drawLine(_pt(pose.elbowL, size), _pt(pose.wristL, size), backLimbPaint);

    // Spine + head
    canvas.drawLine(_pt(shoulderMid, size), _pt(pose.hip, size), torsoPaint);
    canvas.drawLine(_pt(pose.shoulderL, size), _pt(pose.shoulderR, size), backLimbPaint);
    canvas.drawCircle(
      _pt(pose.head, size),
      math.max(size.shortestSide * 0.068, 3.2),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    // Front limbs
    canvas.drawLine(_pt(pose.hip, size), _pt(pose.kneeR, size), frontLimbPaint);
    canvas.drawLine(_pt(pose.kneeR, size), _pt(pose.ankleR, size), frontLimbPaint);
    canvas.drawLine(_pt(pose.shoulderR, size), _pt(pose.elbowR, size), frontLimbPaint);
    canvas.drawLine(_pt(pose.elbowR, size), _pt(pose.wristR, size), frontLimbPaint);

    final jointPaint = Paint()..color = accentColor;
    final jointR = math.max(size.shortestSide * 0.024, 1.5);
    for (final norm in [
      pose.shoulderR,
      pose.elbowR,
      pose.wristR,
      pose.hip,
      pose.kneeR,
    ]) {
      canvas.drawCircle(_pt(norm, size), jointR, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExerciseBiomechanicsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.spec != spec;
  }
}

/// Modal reutilizable con animación GIF del ejercicio, imagen inicial/final, músculos y descripción.
void showExerciseDetailSheet(
  BuildContext context,
  Exercise exercise, {
  VoidCallback? onSelect,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ExerciseMovementPlayer(exercise: exercise),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (exercise.primaryMuscle != null &&
                      exercise.primaryMuscle!.trim().isNotEmpty)
                    Chip(
                      label: Text('Primary: ${exercise.primaryMuscle}'),
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      side: BorderSide.none,
                    ),
                  if (exercise.category != null &&
                      exercise.category!.trim().isNotEmpty)
                    Chip(
                      label: Text('Equipment: ${exercise.category}'),
                      backgroundColor: const Color(0xFF2A2A2A),
                      labelStyle: TextStyle(color: Colors.grey[300]),
                      side: BorderSide.none,
                    ),
                ],
              ),
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Secondary muscles: ${exercise.secondaryMuscles.join(', ')}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                (exercise.description != null &&
                        exercise.description!.trim().isNotEmpty)
                    ? exercise.description!
                    : 'Técnica visual disponible en la animación superior.',
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (onSelect != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onSelect();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Select Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

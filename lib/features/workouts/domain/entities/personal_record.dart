import '../../../../core/utils/weight_converter.dart';

/// Categorías de récord personal que puede superar una serie completada.
enum PersonalRecordType {
  maxWeight,
  repRecord,
  estimated1Rm,
  firstBenchmark,
}

/// Mejor registro histórico consolidado para un ejercicio concreto.
class ExerciseHistoricalBest {
  final int exerciseId;
  final String exerciseName;
  final double maxWeight;
  final int maxRepsAtMaxWeight;
  final double maxEstimated1Rm;

  const ExerciseHistoricalBest({
    required this.exerciseId,
    required this.exerciseName,
    required this.maxWeight,
    required this.maxRepsAtMaxWeight,
    required this.maxEstimated1Rm,
  });

  /// Formatea un peso eliminando decimales `.0` innecesarios.
  static String formatWeight(double weight) {
    if (weight == weight.truncateToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  /// Formatea un peso en kg convirtiéndolo a [unit] sin decimales `.0`.
  static String formatWeightInUnit(double kg, WeightUnit unit) {
    return WeightConverter.formatNumber(WeightConverter.fromKg(kg, unit));
  }

  /// Resumen legible para mostrar en la cabecera del ejercicio durante el entreno.
  String formatSummary() => formatSummaryFor(WeightUnit.kg);

  /// Resumen legible convertido a [unit].
  String formatSummaryFor(WeightUnit unit) {
    final w = formatWeightInUnit(maxWeight, unit);
    final e1rm = WeightConverter.fromKg(maxEstimated1Rm, unit).round();
    return '$w ${unit.label} × $maxRepsAtMaxWeight '
        '(1RM ~$e1rm ${unit.label})';
  }
}

/// Logro de récord personal alcanzado en una serie durante un entrenamiento.
class PersonalRecordAchievement {
  final int exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weight;
  final int reps;
  final double estimated1Rm;
  final double? previousMaxWeight;
  final double? previousMax1Rm;
  final Set<PersonalRecordType> types;

  const PersonalRecordAchievement({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.estimated1Rm,
    this.previousMaxWeight,
    this.previousMax1Rm,
    required this.types,
  });

  String get badgeLabel => '🏆 Nuevo PR';

  String get performanceLabel => performanceLabelFor(WeightUnit.kg);

  String performanceLabelFor(WeightUnit unit) =>
      '${ExerciseHistoricalBest.formatWeightInUnit(weight, unit)} ${unit.label} × $reps';

  /// Explica de forma breve qué marca histórica se ha batido.
  String get improvementLabel => improvementLabelFor(WeightUnit.kg);

  String improvementLabelFor(WeightUnit unit) {
    final unitLbl = unit.label;
    if (types.contains(PersonalRecordType.firstBenchmark)) {
      final est = WeightConverter.fromKg(estimated1Rm, unit).round();
      return '1ª marca: ${performanceLabelFor(unit)} · 1RM ~$est $unitLbl';
    }
    if (types.contains(PersonalRecordType.maxWeight) &&
        previousMaxWeight != null) {
      final diff = weight - previousMaxWeight!;
      return '+${ExerciseHistoricalBest.formatWeightInUnit(diff, unit)} $unitLbl en peso máximo';
    }
    if (types.contains(PersonalRecordType.estimated1Rm) &&
        previousMax1Rm != null) {
      final diff = WeightConverter.fromKg(estimated1Rm - previousMax1Rm!, unit);
      return '+${diff.toStringAsFixed(1)} $unitLbl en 1RM estimado';
    }
    if (types.contains(PersonalRecordType.repRecord)) {
      return 'Más repeticiones con ${ExerciseHistoricalBest.formatWeightInUnit(weight, unit)} $unitLbl';
    }
    return performanceLabelFor(unit);
  }
}

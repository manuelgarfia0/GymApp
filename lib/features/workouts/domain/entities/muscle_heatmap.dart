/// Grupos musculares anatómicos soportados por el mapa de calor corporal.
///
/// Coincide exactamente con los 12 grupos musculares definidos en el catálogo
/// del backend (`exercises.json`).
enum MuscleGroupKey {
  chest,
  shoulders,
  traps,
  biceps,
  triceps,
  forearms,
  core,
  back,
  glutes,
  quadriceps,
  hamstrings,
  calves;

  String get displayNameEs {
    switch (this) {
      case MuscleGroupKey.chest:
        return 'Pecho';
      case MuscleGroupKey.shoulders:
        return 'Hombros';
      case MuscleGroupKey.traps:
        return 'Trapecios';
      case MuscleGroupKey.biceps:
        return 'Bíceps';
      case MuscleGroupKey.triceps:
        return 'Tríceps';
      case MuscleGroupKey.forearms:
        return 'Antebrazos';
      case MuscleGroupKey.core:
        return 'Abdomen / Core';
      case MuscleGroupKey.back:
        return 'Espalda';
      case MuscleGroupKey.glutes:
        return 'Glúteos';
      case MuscleGroupKey.quadriceps:
        return 'Cuádriceps';
      case MuscleGroupKey.hamstrings:
        return 'Femorales';
      case MuscleGroupKey.calves:
        return 'Gemelos';
    }
  }

  bool get isFrontVisible {
    switch (this) {
      case MuscleGroupKey.chest:
      case MuscleGroupKey.shoulders:
      case MuscleGroupKey.traps:
      case MuscleGroupKey.biceps:
      case MuscleGroupKey.forearms:
      case MuscleGroupKey.core:
      case MuscleGroupKey.quadriceps:
      case MuscleGroupKey.calves:
        return true;
      case MuscleGroupKey.triceps:
      case MuscleGroupKey.back:
      case MuscleGroupKey.glutes:
      case MuscleGroupKey.hamstrings:
        return false;
    }
  }

  bool get isBackVisible {
    switch (this) {
      case MuscleGroupKey.traps:
      case MuscleGroupKey.shoulders:
      case MuscleGroupKey.back:
      case MuscleGroupKey.triceps:
      case MuscleGroupKey.forearms:
      case MuscleGroupKey.glutes:
      case MuscleGroupKey.hamstrings:
      case MuscleGroupKey.calves:
        return true;
      case MuscleGroupKey.chest:
      case MuscleGroupKey.biceps:
      case MuscleGroupKey.core:
      case MuscleGroupKey.quadriceps:
        return false;
    }
  }

  static const Map<String, MuscleGroupKey> _rawAliases = {
    'chest': MuscleGroupKey.chest,
    'pectoral': MuscleGroupKey.chest,
    'pectorals': MuscleGroupKey.chest,
    'pectorales': MuscleGroupKey.chest,
    'pecho': MuscleGroupKey.chest,
    'pecs': MuscleGroupKey.chest,
    'shoulders': MuscleGroupKey.shoulders,
    'shoulder': MuscleGroupKey.shoulders,
    'delts': MuscleGroupKey.shoulders,
    'deltoids': MuscleGroupKey.shoulders,
    'deltoides': MuscleGroupKey.shoulders,
    'hombro': MuscleGroupKey.shoulders,
    'hombros': MuscleGroupKey.shoulders,
    'traps': MuscleGroupKey.traps,
    'trap': MuscleGroupKey.traps,
    'trapezius': MuscleGroupKey.traps,
    'trapecio': MuscleGroupKey.traps,
    'trapecios': MuscleGroupKey.traps,
    'biceps': MuscleGroupKey.biceps,
    'bicep': MuscleGroupKey.biceps,
    'bíceps': MuscleGroupKey.biceps,
    'biceps brachii': MuscleGroupKey.biceps,
    'triceps': MuscleGroupKey.triceps,
    'tricep': MuscleGroupKey.triceps,
    'tríceps': MuscleGroupKey.triceps,
    'triceps brachii': MuscleGroupKey.triceps,
    'forearms': MuscleGroupKey.forearms,
    'forearm': MuscleGroupKey.forearms,
    'antebrazo': MuscleGroupKey.forearms,
    'antebrazos': MuscleGroupKey.forearms,
    'core': MuscleGroupKey.core,
    'abs': MuscleGroupKey.core,
    'abdominals': MuscleGroupKey.core,
    'abdominales': MuscleGroupKey.core,
    'abdomen': MuscleGroupKey.core,
    'obliques': MuscleGroupKey.core,
    'oblicuos': MuscleGroupKey.core,
    'back': MuscleGroupKey.back,
    'lats': MuscleGroupKey.back,
    'latissimus': MuscleGroupKey.back,
    'latissimus dorsi': MuscleGroupKey.back,
    'dorsal': MuscleGroupKey.back,
    'dorsales': MuscleGroupKey.back,
    'espalda': MuscleGroupKey.back,
    'lower back': MuscleGroupKey.back,
    'upper back': MuscleGroupKey.back,
    'lumbar': MuscleGroupKey.back,
    'lumbares': MuscleGroupKey.back,
    'glutes': MuscleGroupKey.glutes,
    'glute': MuscleGroupKey.glutes,
    'gluteus': MuscleGroupKey.glutes,
    'gluteo': MuscleGroupKey.glutes,
    'glúteo': MuscleGroupKey.glutes,
    'gluteos': MuscleGroupKey.glutes,
    'glúteos': MuscleGroupKey.glutes,
    'quadriceps': MuscleGroupKey.quadriceps,
    'quads': MuscleGroupKey.quadriceps,
    'quad': MuscleGroupKey.quadriceps,
    'cuadriceps': MuscleGroupKey.quadriceps,
    'cuádriceps': MuscleGroupKey.quadriceps,
    'hamstrings': MuscleGroupKey.hamstrings,
    'hamstring': MuscleGroupKey.hamstrings,
    'femorales': MuscleGroupKey.hamstrings,
    'femoral': MuscleGroupKey.hamstrings,
    'isquiotibiales': MuscleGroupKey.hamstrings,
    'isquios': MuscleGroupKey.hamstrings,
    'calves': MuscleGroupKey.calves,
    'calf': MuscleGroupKey.calves,
    'gemelo': MuscleGroupKey.calves,
    'gemelos': MuscleGroupKey.calves,
    'pantorrilla': MuscleGroupKey.calves,
    'pantorrillas': MuscleGroupKey.calves,
  };

  /// Convierte el nombre de un músculo recibido de la API o catálogo al grupo
  /// anatómico correspondiente, o `null` si no coincide con ninguno.
  static MuscleGroupKey? fromRawName(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _rawAliases[normalized];
  }
}

/// Ventanas temporales disponibles para filtrar el mapa de calor muscular.
enum MuscleHeatmapRange {
  lastWorkout,
  last7Days,
  last30Days,
  allTime;

  String get labelEs {
    switch (this) {
      case MuscleHeatmapRange.lastWorkout:
        return 'Última';
      case MuscleHeatmapRange.last7Days:
        return '7 días';
      case MuscleHeatmapRange.last30Days:
        return '30 días';
      case MuscleHeatmapRange.allTime:
        return 'Todo';
    }
  }
}

/// Desglose de un ejercicio concreto dentro de la actividad de un músculo.
class MuscleExerciseBreakdown {
  final String exerciseName;
  final int sets;
  final double volume;
  final bool isPrimary;

  const MuscleExerciseBreakdown({
    required this.exerciseName,
    required this.sets,
    required this.volume,
    required this.isPrimary,
  });
}

/// Actividad agregada para un grupo muscular en un periodo o sesión.
class MuscleActivity {
  final MuscleGroupKey muscle;
  final int primarySets;
  final int secondarySets;
  final double effectiveSets;
  final double totalVolume;
  final double intensity;
  final int intensityLevel;
  final List<MuscleExerciseBreakdown> exercises;

  const MuscleActivity({
    required this.muscle,
    this.primarySets = 0,
    this.secondarySets = 0,
    this.effectiveSets = 0,
    this.totalVolume = 0,
    this.intensity = 0,
    this.intensityLevel = 0,
    this.exercises = const [],
  });

  factory MuscleActivity.empty(MuscleGroupKey muscle) =>
      MuscleActivity(muscle: muscle);
}

/// Resultado completo del cálculo de mapa de calor muscular anatómico.
class MuscleHeatmapData {
  final Map<MuscleGroupKey, MuscleActivity> activities;
  final int workoutCount;
  final double totalEffectiveSets;
  final MuscleGroupKey? topMuscle;

  const MuscleHeatmapData({
    required this.activities,
    required this.workoutCount,
    required this.totalEffectiveSets,
    this.topMuscle,
  });

  static const empty = MuscleHeatmapData(
    activities: {},
    workoutCount: 0,
    totalEffectiveSets: 0,
  );

  bool get isEmpty => activities.values.every((a) => a.effectiveSets <= 0);

  List<MuscleActivity> get activeMusclesSorted {
    final active = activities.values
        .where((a) => a.effectiveSets > 0)
        .toList();
    active.sort((a, b) {
      final setsCmp = b.effectiveSets.compareTo(a.effectiveSets);
      if (setsCmp != 0) return setsCmp;
      final volCmp = b.totalVolume.compareTo(a.totalVolume);
      if (volCmp != 0) return volCmp;
      return a.muscle.index.compareTo(b.muscle.index);
    });
    return active;
  }

  MuscleActivity activityFor(MuscleGroupKey key) =>
      activities[key] ?? MuscleActivity.empty(key);
}

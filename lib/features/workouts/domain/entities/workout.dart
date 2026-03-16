/// Entidad de dominio que representa una sesión de entrenamiento.
class Workout {
  final int? id;
  final String name;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final int userId;
  final int? routineId;
  final List<WorkoutSet> sets;

  const Workout({
    this.id,
    required this.name,
    this.notes,
    required this.startTime,
    this.endTime,
    required this.userId,
    this.routineId,
    required this.sets,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout &&
        other.id == id &&
        other.name == name &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.userId == userId &&
        other.routineId == routineId;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, startTime, endTime, userId, routineId);

  @override
  String toString() =>
      'Workout(id: $id, name: $name, startTime: $startTime, sets: ${sets.length})';
}

/// Entidad de dominio que representa una serie dentro de un entrenamiento.
class WorkoutSet {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;
  final DateTime timestamp; // uso local solamente
  final String? notes;
  final bool isModified;
  // AÑADIDOS: campos que existen en el backend
  final bool isWarmup;
  final bool isCompleted;

  const WorkoutSet({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.exerciseOrder,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.timestamp,
    this.notes,
    this.isModified = false,
    this.isWarmup = false,
    this.isCompleted = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSet &&
        other.exerciseId == exerciseId &&
        other.exerciseOrder == exerciseOrder &&
        other.setNumber == setNumber &&
        other.weight == weight &&
        other.reps == reps;
  }

  @override
  int get hashCode =>
      Object.hash(exerciseId, exerciseOrder, setNumber, weight, reps);

  @override
  String toString() =>
      'WorkoutSet(exerciseId: $exerciseId, setNumber: $setNumber, weight: $weight, reps: $reps)';
}

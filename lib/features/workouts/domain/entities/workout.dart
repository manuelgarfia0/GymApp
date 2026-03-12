/// Pure Dart entity representing a workout session in the domain layer.
/// Contains no Flutter dependencies and represents the business concept of a completed workout.
class Workout {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final int userId;
  final int? routineId;
  final List<WorkoutSet> sets;

  const Workout({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.userId,
    this.routineId,
    required this.sets,
  });

  /// Returns true if the workout is currently active (not finished).
  bool get isActive => endTime == null;

  /// Returns the duration of the workout if completed, or current duration if active.
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
        other.routineId == routineId &&
        _listEquals(other.sets, sets);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      startTime,
      endTime,
      userId,
      routineId,
      sets.length,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Workout(id: $id, name: $name, startTime: $startTime, sets: ${sets.length})';
  }
}

/// Pure Dart entity representing a set performed during a workout.
/// Contains the actual performance data for an exercise set.
class WorkoutSet {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;
  final DateTime timestamp;
  final String? notes;
  final bool isModified;

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
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSet &&
        other.exerciseId == exerciseId &&
        other.exerciseName == exerciseName &&
        other.exerciseOrder == exerciseOrder &&
        other.setNumber == setNumber &&
        other.weight == weight &&
        other.reps == reps &&
        other.timestamp == timestamp &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      exerciseId,
      exerciseName,
      exerciseOrder,
      setNumber,
      weight,
      reps,
      timestamp,
      notes,
    );
  }

  @override
  String toString() {
    return 'WorkoutSet(exerciseId: $exerciseId, setNumber: $setNumber, weight: $weight, reps: $reps)';
  }
}

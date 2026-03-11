import '../../domain/entities/workout.dart';

/// Data Transfer Object for Workout
/// Handles JSON serialization/deserialization with the Spring Boot backend
class WorkoutDto {
  final int? id;
  final String name;
  final String startTime;
  final String? endTime;
  final int userId;
  final int? routineId;
  final List<WorkoutSetDto> sets;

  const WorkoutDto({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.userId,
    this.routineId,
    required this.sets,
  });

  /// Creates WorkoutDto from JSON response from Spring Boot API
  factory WorkoutDto.fromJson(Map<String, dynamic> json) {
    return WorkoutDto(
      id: json['id'] as int?,
      name: json['name'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      userId: json['userId'] as int,
      routineId: json['routineId'] as int?,
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSetDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts WorkoutDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'userId': userId,
      if (routineId != null) 'routineId': routineId,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  /// Converts DTO to domain entity
  /// This ensures clean separation between data and domain layers
  Workout toEntity() {
    return Workout(
      id: id,
      name: name,
      startTime: DateTime.parse(startTime),
      endTime: endTime != null ? DateTime.parse(endTime!) : null,
      userId: userId,
      routineId: routineId,
      sets: sets.map((e) => e.toEntity()).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutDto &&
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
    return 'WorkoutDto(id: $id, name: $name, startTime: $startTime, sets: ${sets.length})';
  }
}

/// Data Transfer Object for WorkoutSet
/// Handles JSON serialization/deserialization for sets within workouts
class WorkoutSetDto {
  final int exerciseId;
  final String? exerciseName;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;
  final String timestamp;
  final String? notes;

  const WorkoutSetDto({
    required this.exerciseId,
    this.exerciseName,
    required this.exerciseOrder,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.timestamp,
    this.notes,
  });

  /// Creates WorkoutSetDto from JSON response from Spring Boot API
  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDto(
      exerciseId: json['exerciseId'] as int,
      exerciseName: json['exerciseName'] as String?,
      exerciseOrder: json['exerciseOrder'] as int,
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      timestamp: json['timestamp'] as String,
      notes: json['notes'] as String?,
    );
  }

  /// Converts WorkoutSetDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      if (exerciseName != null) 'exerciseName': exerciseName,
      'exerciseOrder': exerciseOrder,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'timestamp': timestamp,
      if (notes != null) 'notes': notes,
    };
  }

  /// Converts DTO to domain entity
  /// This ensures clean separation between data and domain layers
  WorkoutSet toEntity() {
    return WorkoutSet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseOrder: exerciseOrder,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      timestamp: DateTime.parse(timestamp),
      notes: notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSetDto &&
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
    return 'WorkoutSetDto(exerciseId: $exerciseId, setNumber: $setNumber, weight: $weight, reps: $reps)';
  }
}

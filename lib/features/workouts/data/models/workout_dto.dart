import '../../domain/entities/workout.dart';

/// Data Transfer Object para Workout
/// Maneja la serialización/deserialización JSON con el backend Spring Boot
class WorkoutDto {
  final int? id;
  final String name;
  final String?
  startTime; // Cambiado a nullable para manejar valores nulos del backend
  final String? endTime;
  final int userId;
  final int? routineId;
  final List<WorkoutSetDto> sets;

  const WorkoutDto({
    this.id,
    required this.name,
    this.startTime, // Cambiado a opcional para manejar valores nulos
    this.endTime,
    required this.userId,
    this.routineId,
    required this.sets,
  });

  /// Crea WorkoutDto desde respuesta JSON de la API Spring Boot
  factory WorkoutDto.fromJson(Map<String, dynamic> json) {
    return WorkoutDto(
      id: json['id'] as int?,
      name: json['name'] as String,
      startTime:
          json['startTime'] as String?, // Maneja valores nulos apropiadamente
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

  /// Convierte WorkoutDto a JSON para peticiones API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (startTime != null)
        'startTime': startTime, // Solo incluye si no es nulo
      if (endTime != null) 'endTime': endTime,
      'userId': userId,
      if (routineId != null) 'routineId': routineId,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  /// Convierte DTO a entidad del dominio
  /// Esto asegura separación limpia entre capas de datos y dominio
  Workout toEntity() {
    return Workout(
      id: id,
      name: name,
      startTime: startTime != null
          ? DateTime.parse(startTime!)
          : DateTime.now(), // Fallback a tiempo actual si es nulo
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

/// Data Transfer Object para WorkoutSet
/// Maneja la serialización/deserialización JSON para sets dentro de workouts
class WorkoutSetDto {
  final int exerciseId;
  final String? exerciseName;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;
  final String?
  timestamp; // Cambiado a nullable para manejar valores nulos del backend
  final String? notes;

  const WorkoutSetDto({
    required this.exerciseId,
    this.exerciseName,
    required this.exerciseOrder,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.timestamp, // Cambiado a opcional para manejar valores nulos
    this.notes,
  });

  /// Crea WorkoutSetDto desde respuesta JSON de la API Spring Boot
  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDto(
      exerciseId: json['exerciseId'] as int,
      exerciseName: json['exerciseName'] as String?,
      exerciseOrder: json['exerciseOrder'] as int,
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      timestamp:
          json['timestamp'] as String?, // Maneja valores nulos apropiadamente
      notes: json['notes'] as String?,
    );
  }

  /// Convierte WorkoutSetDto a JSON para peticiones API
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      if (exerciseName != null) 'exerciseName': exerciseName,
      'exerciseOrder': exerciseOrder,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      if (timestamp != null)
        'timestamp': timestamp, // Solo incluye si no es nulo
      if (notes != null) 'notes': notes,
    };
  }

  /// Convierte DTO a entidad del dominio
  /// Esto asegura separación limpia entre capas de datos y dominio
  WorkoutSet toEntity() {
    return WorkoutSet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseOrder: exerciseOrder,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      timestamp: timestamp != null
          ? DateTime.parse(timestamp!)
          : DateTime.now(), // Fallback a tiempo actual si es nulo
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

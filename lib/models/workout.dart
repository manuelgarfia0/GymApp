class WorkoutSetDTO {
  final int exerciseId;
  final String? exerciseName;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;

  WorkoutSetDTO({
    required this.exerciseId,
    this.exerciseName,
    required this.exerciseOrder,
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  factory WorkoutSetDTO.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDTO(
      exerciseId: json['exerciseId'] ?? 0,
      exerciseName: json['exerciseName'],
      exerciseOrder: json['exerciseOrder'] ?? 1,
      setNumber: json['setNumber'] ?? 1,
      weight: (json['weight'] ?? 0).toDouble(),
      reps: json['reps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseOrder': exerciseOrder,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
    };
  }
}

class WorkoutDTO {
  final int? id;
  final String name;
  final String startTime;
  final String? endTime; // ¡NUEVO! Guardamos la hora de fin
  final int userId;
  final int? routineId;
  final List<WorkoutSetDTO> sets;

  WorkoutDTO({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime, // Añadido al constructor
    required this.userId,
    this.routineId,
    required this.sets,
  });

  factory WorkoutDTO.fromJson(Map<String, dynamic> json) {
    List<WorkoutSetDTO> parsedSets = [];
    if (json['sets'] != null) {
      parsedSets = (json['sets'] as List).map((i) => WorkoutSetDTO.fromJson(i)).toList();
    }

    return WorkoutDTO(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Workout',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'], // Lo leemos del JSON
      userId: json['userId'] ?? 0,
      routineId: json['routineId'],
      sets: parsedSets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startTime': startTime,
      'endTime': endTime, // Lo enviamos al JSON
      'userId': userId,
      'routineId': routineId,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}
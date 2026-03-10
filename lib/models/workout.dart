class WorkoutSetDTO {
  final int exerciseId;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;

  WorkoutSetDTO({
    required this.exerciseId,
    required this.exerciseOrder,
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

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
  final String name;
  final String startTime;
  final int userId; // ¡Importante! El backend lo pide obligatorio
  final List<WorkoutSetDTO> sets;

  WorkoutDTO({
    required this.name,
    required this.startTime,
    required this.userId,
    required this.sets,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startTime': startTime,
      'userId': userId,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}
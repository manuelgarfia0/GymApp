class Exercise {
  final int id;
  final String name;
  final String description;
  final String primaryMuscleName;
  final String equipmentName;
  final List<String> secondaryMuscleNames;

  Exercise({
    required this.id,
    required this.name,
    this.description = 'No description provided',
    this.primaryMuscleName = 'Unspecified',
    this.equipmentName = 'Bodyweight',
    this.secondaryMuscleNames = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    List<String> parsedSecondary = [];
    if (json['secondaryMuscleNames'] != null) {
      parsedSecondary = List<String>.from(json['secondaryMuscleNames']);
    }

    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? 'No description provided',
      primaryMuscleName: json['primaryMuscleName'] ?? 'Unspecified',
      equipmentName: json['equipmentName'] ?? 'Bodyweight',
      secondaryMuscleNames: parsedSecondary,
    );
  }
}
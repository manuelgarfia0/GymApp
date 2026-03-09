class Exercise {
  final int id;
  final String name;
  final String description;
  final String primaryMuscle;
  final String equipment;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    required this.equipment,
  });

  // Convierte el JSON de la API a un objeto de Dart
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? 'Sin descripción',
      primaryMuscle: json['primaryMuscle'] ?? 'General',
      equipment: json['equipment'] ?? 'Bodyweight',
    );
  }
}
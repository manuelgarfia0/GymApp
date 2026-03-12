/// Entidad Dart pura que representa un ejercicio en la capa de dominio.
/// No contiene dependencias de Flutter y representa el concepto de negocio de un ejercicio.
class Exercise {
  final int id;
  final String name;
  final String? description; // Cambiado a nullable para consistencia con DTO
  final String? primaryMuscle; // Cambiado a nullable para consistencia con DTO
  final String equipment;
  final List<String> secondaryMuscles;

  const Exercise({
    required this.id,
    required this.name,
    this.description, // Cambiado a opcional para manejar valores nulos
    this.primaryMuscle, // Cambiado a opcional para manejar valores nulos
    required this.equipment,
    required this.secondaryMuscles,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.primaryMuscle == primaryMuscle &&
        other.equipment == equipment &&
        _listEquals(other.secondaryMuscles, secondaryMuscles);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      primaryMuscle,
      equipment,
      secondaryMuscles.length,
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
    return 'Exercise(id: $id, name: $name, primaryMuscle: $primaryMuscle, equipment: $equipment)';
  }
}

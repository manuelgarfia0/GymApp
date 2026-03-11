import '../entities/exercise.dart';

/// Interfaz de repositorio para operaciones de datos de ejercicios.
/// Define el contrato para el acceso a datos de ejercicios sin detalles de implementación.
/// Esta interfaz será implementada en la capa de datos.
abstract class ExerciseRepository {
  /// Obtiene todos los ejercicios disponibles desde la fuente de datos.
  /// Retorna una lista de entidades Exercise.
  /// Lanza una excepción si la operación falla.
  Future<List<Exercise>> getExercises();

  /// Obtiene un ejercicio específico por su ID.
  /// Retorna la entidad Exercise si se encuentra, null en caso contrario.
  /// Lanza una excepción si la operación falla.
  Future<Exercise?> getExerciseById(int id);

  /// Busca ejercicios por nombre o grupo muscular.
  /// Retorna una lista de entidades Exercise que coinciden.
  /// Lanza una excepción si la operación falla.
  Future<List<Exercise>> searchExercises(String query);
}

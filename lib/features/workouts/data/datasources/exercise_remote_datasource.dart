import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/exercise_dto.dart';

abstract class ExerciseRemoteDatasource {
  Future<List<ExerciseDto>> getExercises();
  Future<ExerciseDto?> getExerciseById(int id);
  Future<List<ExerciseDto>> searchExercises(String query);
}

class ExerciseRemoteDatasourceImpl implements ExerciseRemoteDatasource {
  final ApiClient apiClient;

  const ExerciseRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<ExerciseDto>> getExercises() async {
    try {
      // El backend devuelve un objeto Page con paginación
      // Parámetros por defecto: page=0, size=100 para cargar todos de una vez
      final uri = Uri.parse(
        ApiConstants.exercisesEndpoint,
      ).replace(queryParameters: {'page': '0', 'size': '100'});

      final response = await apiClient.get(uri);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        // El backend devuelve Page<ExerciseDTO>, no List<ExerciseDTO>
        // Estructura: { "content": [...], "totalElements": N, ... }
        final pageData = jsonDecode(responseBody) as Map<String, dynamic>;
        final data = pageData['content'] as List<dynamic>;

        return data
            .map((json) => ExerciseDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get exercises';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<ExerciseDto?> getExerciseById(int id) async {
    try {
      final response = await apiClient.get(
        Uri.parse('${ApiConstants.exercisesEndpoint}/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ExerciseDto.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get exercise';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<List<ExerciseDto>> searchExercises(String query) async {
    try {
      // El endpoint de búsqueda devuelve List<ExerciseDTO> directamente (sin paginación)
      final uri = Uri.parse(
        ApiConstants.exercisesEndpoint,
      ).replace(queryParameters: {'search': query});

      final response = await apiClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) => ExerciseDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to search exercises';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }
}

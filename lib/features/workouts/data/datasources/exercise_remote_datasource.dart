import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/exercise_dto.dart';

/// Abstract interface for exercise remote data source
abstract class ExerciseRemoteDatasource {
  /// Retrieves all available exercises from the API
  /// Returns list of ExerciseDto on success
  /// Throws exception on failure
  Future<List<ExerciseDto>> getExercises();

  /// Retrieves a specific exercise by its ID from the API
  /// Returns ExerciseDto if found, null otherwise
  /// Throws exception on failure
  Future<ExerciseDto?> getExerciseById(int id);

  /// Searches for exercises by name or muscle group
  /// Returns list of matching ExerciseDto on success
  /// Throws exception on failure
  Future<List<ExerciseDto>> searchExercises(String query);
}

/// Implementation of ExerciseRemoteDatasource using HTTP API
class ExerciseRemoteDatasourceImpl implements ExerciseRemoteDatasource {
  final ApiClient apiClient;

  const ExerciseRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<ExerciseDto>> getExercises() async {
    try {
      final response = await apiClient.get(
        Uri.parse(ApiConstants.exercisesEndpoint),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('🔍 Exercise API Response: $responseBody');

        final data = jsonDecode(responseBody) as List<dynamic>;
        print('🔍 Parsed data length: ${data.length}');

        // Log first exercise for debugging
        if (data.isNotEmpty) {
          print('🔍 First exercise data: ${data.first}');
        }

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

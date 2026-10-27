import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/workout_dto.dart';

abstract class WorkoutRemoteDatasource {
  Future<List<WorkoutDto>> getUserWorkouts(int userId);
  Future<WorkoutDto?> getWorkoutById(int id);
  Future<WorkoutDto> createWorkout(WorkoutDto workout);
  Future<WorkoutDto> updateWorkout(WorkoutDto workout);
  Future<WorkoutDto> endWorkout(int workoutId);
  Future<bool> deleteWorkout(int id);
}

class WorkoutRemoteDatasourceImpl implements WorkoutRemoteDatasource {
  final ApiClient apiClient;

  const WorkoutRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<WorkoutDto>> getUserWorkouts(int userId) async {
    try {
      final uri = Uri.parse('${ApiConstants.workoutsEndpoint}/user/$userId');

      final response = await apiClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) => WorkoutDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to get user workouts',
        );
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
  Future<WorkoutDto?> getWorkoutById(int id) async {
    try {
      final response = await apiClient.get(
        Uri.parse('${ApiConstants.workoutsEndpoint}/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkoutDto.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to get workout',
        );
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
  Future<WorkoutDto> createWorkout(WorkoutDto workout) async {
    try {
      final response = await apiClient.post(
        Uri.parse(ApiConstants.workoutsEndpoint),
        body: jsonEncode(workout.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkoutDto.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['message'] as String?;
        final fieldErrors = errorData?['fieldErrors'] as Map<String, dynamic>?;
        throw Exception(
          message ?? fieldErrors?.toString() ?? 'Invalid workout data',
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to create workout',
        );
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
  Future<WorkoutDto> updateWorkout(WorkoutDto workout) async {
    try {
      final response = await apiClient.put(
        Uri.parse('${ApiConstants.workoutsEndpoint}/${workout.id}'),
        body: jsonEncode(workout.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkoutDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Workout not found');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to update workout',
        );
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
  Future<bool> deleteWorkout(int id) async {
    try {
      final response = await apiClient.delete(
        Uri.parse('${ApiConstants.workoutsEndpoint}/$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to delete workout',
        );
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
  Future<WorkoutDto> endWorkout(int workoutId) async {
    try {
      final response = await apiClient.patch(
        Uri.parse('${ApiConstants.workoutsEndpoint}/$workoutId/end'),
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkoutDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Workout not found');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to end workout',
        );
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

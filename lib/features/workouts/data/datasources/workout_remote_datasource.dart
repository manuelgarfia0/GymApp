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
  // ELIMINADOS:
  //   saveWorkout  → llamaba a POST /api/workouts/save (endpoint eliminado del backend)
  //   getActiveWorkout → llamaba a GET /api/workouts/active (endpoint eliminado del backend)
}

class WorkoutRemoteDatasourceImpl implements WorkoutRemoteDatasource {
  final ApiClient apiClient;

  const WorkoutRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<WorkoutDto>> getUserWorkouts(int userId) async {
    try {
      // GET /api/workouts?userId={userId}
      final uri = Uri.parse(
        ApiConstants.workoutsEndpoint,
      ).replace(queryParameters: {'userId': userId.toString()});

      final response = await apiClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) => WorkoutDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
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
  Future<WorkoutDto> endWorkout(int workoutId) async {
    try {
      // PATCH /api/workouts/{id}/end — el backend setea endTime = now()
      // No hace falta enviar body, el backend usa LocalDateTime.now()
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

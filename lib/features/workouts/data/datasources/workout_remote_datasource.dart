import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/workout_dto.dart';

/// Abstract interface for workout remote data source
abstract class WorkoutRemoteDatasource {
  /// Retrieves all workouts for a specific user from the API
  /// Returns list of WorkoutDto belonging to the user
  /// Throws exception on failure
  Future<List<WorkoutDto>> getUserWorkouts(int userId);

  /// Retrieves a specific workout by its ID from the API
  /// Returns WorkoutDto if found, null otherwise
  /// Throws exception on failure
  Future<WorkoutDto?> getWorkoutById(int id);

  /// Creates a new workout session via the API
  /// Returns the created WorkoutDto with assigned ID
  /// Throws exception on failure
  Future<WorkoutDto> createWorkout(WorkoutDto workout);

  /// Updates an existing workout via the API
  /// Returns the updated WorkoutDto
  /// Throws exception on failure
  Future<WorkoutDto> updateWorkout(WorkoutDto workout);

  /// Saves a completed workout with all its sets via the API
  /// Returns true if save was successful
  /// Throws exception on failure
  Future<bool> saveWorkout(WorkoutDto workout);

  /// Retrieves the current active workout for a user from the API
  /// Returns active WorkoutDto if found, null otherwise
  /// Throws exception on failure
  Future<WorkoutDto?> getActiveWorkout(int userId);

  /// Ends an active workout by setting the end time via the API
  /// Returns the completed WorkoutDto
  /// Throws exception on failure
  Future<WorkoutDto> endWorkout(int workoutId);
}

/// Implementation of WorkoutRemoteDatasource using HTTP API
class WorkoutRemoteDatasourceImpl implements WorkoutRemoteDatasource {
  final ApiClient apiClient;

  const WorkoutRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<WorkoutDto>> getUserWorkouts(int userId) async {
    try {
      final uri = Uri.parse(
        ApiConstants.workoutsEndpoint,
      ).replace(queryParameters: {'userId': userId.toString()});

      print('🔍 Workout API: Calling ${uri.toString()}');
      final response = await apiClient.get(uri);
      print('🔍 Workout API: Response status ${response.statusCode}');
      print('🔍 Workout API: Response body ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        print('🔍 Workout API: Parsed ${data.length} workouts');
        return data
            .map((json) => WorkoutDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get user workouts';
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      print('🔍 Workout API: SocketException - $e');
      throw Exception('No internet connection');
    } on FormatException catch (e) {
      print('🔍 Workout API: FormatException - $e');
      throw Exception('Invalid response format');
    } catch (e) {
      print('🔍 Workout API: Unexpected error - $e');
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
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get workout';
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
        final errorMessage =
            errorData?['message'] as String? ?? 'Invalid workout data';
        throw Exception(errorMessage);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to create workout';
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
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Invalid workout data';
        throw Exception(errorMessage);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to update workout';
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
  Future<bool> saveWorkout(WorkoutDto workout) async {
    try {
      final response = await apiClient.post(
        Uri.parse('${ApiConstants.workoutsEndpoint}/save'),
        body: jsonEncode(workout.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Invalid workout data';
        throw Exception(errorMessage);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to save workout';
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
  Future<WorkoutDto?> getActiveWorkout(int userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.workoutsEndpoint}/active',
      ).replace(queryParameters: {'userId': userId.toString()});

      final response = await apiClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkoutDto.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get active workout';
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
  Future<WorkoutDto> endWorkout(int workoutId) async {
    try {
      final response = await apiClient.patch(
        Uri.parse('${ApiConstants.workoutsEndpoint}/$workoutId/end'),
        body: jsonEncode({'endTime': DateTime.now().toIso8601String()}),
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
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to end workout';
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

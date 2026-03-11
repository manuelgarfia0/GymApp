import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/workout_remote_datasource.dart';
import '../models/workout_dto.dart';

/// Implementation of WorkoutRepository that bridges datasource and domain
/// Handles API communication and transforms DTOs to entities
class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDatasource remoteDatasource;

  const WorkoutRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Workout>> getUserWorkouts(int userId) async {
    try {
      // Validate input
      if (userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Get workouts from remote datasource
      final workoutDtos = await remoteDatasource.getUserWorkouts(userId);

      // Transform DTOs to entities before returning to domain layer
      return workoutDtos.map((dto) => dto.toEntity()).toList();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('404')) {
        throw const NetworkFailure('Workout service not available');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to load workouts: ${e.toString()}');
    }
  }

  @override
  Future<Workout?> getWorkoutById(int id) async {
    try {
      // Validate input
      if (id <= 0) {
        throw const ValidationFailure('Valid workout ID is required');
      }

      // Get workout from remote datasource
      final workoutDto = await remoteDatasource.getWorkoutById(id);

      // Transform DTO to entity before returning to domain layer
      return workoutDto?.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('404')) {
        // Return null for not found workouts (valid case)
        return null;
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to load workout: ${e.toString()}');
    }
  }

  @override
  Future<Workout> createWorkout(Workout workout) async {
    try {
      // Validate input
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure('Workout name cannot be empty');
      }
      if (workout.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Convert entity to DTO for API communication
      final workoutDto = _workoutToDto(workout);

      // Create workout via remote datasource
      final createdDto = await remoteDatasource.createWorkout(workoutDto);

      // Transform DTO to entity before returning to domain layer
      return createdDto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('400') ||
          errorMessage.contains('bad request')) {
        throw const ValidationFailure('Invalid workout data provided');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to create workout: ${e.toString()}');
    }
  }

  @override
  Future<Workout> updateWorkout(Workout workout) async {
    try {
      // Validate input
      if (workout.id == null || workout.id! <= 0) {
        throw const ValidationFailure(
          'Valid workout ID is required for update',
        );
      }
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure('Workout name cannot be empty');
      }
      if (workout.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Convert entity to DTO for API communication
      final workoutDto = _workoutToDto(workout);

      // Update workout via remote datasource
      final updatedDto = await remoteDatasource.updateWorkout(workoutDto);

      // Transform DTO to entity before returning to domain layer
      return updatedDto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('400') ||
          errorMessage.contains('bad request')) {
        throw const ValidationFailure('Invalid workout data provided');
      } else if (errorMessage.contains('404')) {
        throw const ValidationFailure('Workout not found or has been deleted');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to update workout: ${e.toString()}');
    }
  }

  @override
  Future<bool> saveWorkout(Workout workout) async {
    try {
      // Validate input
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure('Workout name cannot be empty');
      }
      if (workout.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Convert entity to DTO for API communication
      final workoutDto = _workoutToDto(workout);

      // Save workout via remote datasource
      return await remoteDatasource.saveWorkout(workoutDto);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('400') ||
          errorMessage.contains('bad request')) {
        throw const ValidationFailure('Invalid workout data provided');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to save workout: ${e.toString()}');
    }
  }

  @override
  Future<Workout?> getActiveWorkout(int userId) async {
    try {
      // Validate input
      if (userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Get active workout from remote datasource
      final workoutDto = await remoteDatasource.getActiveWorkout(userId);

      // Transform DTO to entity before returning to domain layer
      return workoutDto?.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('404')) {
        // Return null for no active workout (valid case)
        return null;
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to get active workout: ${e.toString()}');
    }
  }

  @override
  Future<Workout> endWorkout(int workoutId) async {
    try {
      // Validate input
      if (workoutId <= 0) {
        throw const ValidationFailure('Valid workout ID is required');
      }

      // End workout via remote datasource
      final endedDto = await remoteDatasource.endWorkout(workoutId);

      // Transform DTO to entity before returning to domain layer
      return endedDto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow; // Re-throw validation failures as-is
    } catch (e) {
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (errorMessage.contains('404')) {
        throw const ValidationFailure('Workout not found or has already ended');
      } else if (errorMessage.contains('400') ||
          errorMessage.contains('bad request')) {
        throw const ValidationFailure('Cannot end workout in current state');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to end workout: ${e.toString()}');
    }
  }

  /// Converts domain Workout entity to WorkoutDto for API communication
  WorkoutDto _workoutToDto(Workout workout) {
    return WorkoutDto(
      id: workout.id,
      name: workout.name,
      startTime: workout.startTime.toIso8601String(),
      endTime: workout.endTime?.toIso8601String(),
      userId: workout.userId,
      routineId: workout.routineId,
      sets: workout.sets.map((set) => _workoutSetToDto(set)).toList(),
    );
  }

  /// Converts domain WorkoutSet entity to WorkoutSetDto for API communication
  WorkoutSetDto _workoutSetToDto(WorkoutSet set) {
    return WorkoutSetDto(
      exerciseId: set.exerciseId,
      exerciseName: set.exerciseName,
      exerciseOrder: set.exerciseOrder,
      setNumber: set.setNumber,
      weight: set.weight,
      reps: set.reps,
      timestamp: set.timestamp.toIso8601String(),
      notes: set.notes,
    );
  }
}

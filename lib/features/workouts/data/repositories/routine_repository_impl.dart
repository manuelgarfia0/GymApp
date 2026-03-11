import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/routine_remote_datasource.dart';
import '../models/routine_dto.dart';

/// Implementation of RoutineRepository that bridges datasource and domain
/// Handles API communication and transforms DTOs to entities
class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineRemoteDatasource remoteDatasource;

  const RoutineRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Routine>> getUserRoutines(int userId) async {
    try {
      // Validate input
      if (userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Get routines from remote datasource
      final routineDtos = await remoteDatasource.getUserRoutines(userId);

      // Transform DTOs to entities before returning to domain layer
      return routineDtos.map((dto) => dto.toEntity()).toList();
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
        throw const NetworkFailure('Routine service not available');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to load routines: ${e.toString()}');
    }
  }

  @override
  Future<Routine?> getRoutineById(int id) async {
    try {
      // Validate input
      if (id <= 0) {
        throw const ValidationFailure('Valid routine ID is required');
      }

      // Get routine from remote datasource
      final routineDto = await remoteDatasource.getRoutineById(id);

      // Transform DTO to entity before returning to domain layer
      return routineDto?.toEntity();
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
        // Return null for not found routines (valid case)
        return null;
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to load routine: ${e.toString()}');
    }
  }

  @override
  Future<Routine> createRoutine(Routine routine) async {
    try {
      // Validate input
      if (routine.name.trim().isEmpty) {
        throw const ValidationFailure('Routine name cannot be empty');
      }
      if (routine.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Convert entity to DTO for API communication
      final routineDto = _routineToDto(routine);

      // Create routine via remote datasource
      final createdDto = await remoteDatasource.createRoutine(routineDto);

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
        throw const ValidationFailure('Invalid routine data provided');
      } else if (errorMessage.contains('409') ||
          errorMessage.contains('conflict')) {
        throw const ValidationFailure(
          'A routine with this name already exists',
        );
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to create routine: ${e.toString()}');
    }
  }

  @override
  Future<Routine> updateRoutine(Routine routine) async {
    try {
      // Validate input
      if (routine.id == null || routine.id! <= 0) {
        throw const ValidationFailure(
          'Valid routine ID is required for update',
        );
      }
      if (routine.name.trim().isEmpty) {
        throw const ValidationFailure('Routine name cannot be empty');
      }
      if (routine.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      // Convert entity to DTO for API communication
      final routineDto = _routineToDto(routine);

      // Update routine via remote datasource
      final updatedDto = await remoteDatasource.updateRoutine(routineDto);

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
        throw const ValidationFailure('Invalid routine data provided');
      } else if (errorMessage.contains('404')) {
        throw const ValidationFailure('Routine not found or has been deleted');
      } else if (errorMessage.contains('409') ||
          errorMessage.contains('conflict')) {
        throw const ValidationFailure(
          'A routine with this name already exists',
        );
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to update routine: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteRoutine(int id) async {
    try {
      // Validate input
      if (id <= 0) {
        throw const ValidationFailure('Valid routine ID is required');
      }

      // Delete routine via remote datasource
      return await remoteDatasource.deleteRoutine(id);
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
        // Return false for not found routines (already deleted)
        return false;
      } else if (errorMessage.contains('409') ||
          errorMessage.contains('conflict')) {
        throw const ValidationFailure(
          'Cannot delete routine that is currently in use',
        );
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to delete routine: ${e.toString()}');
    }
  }

  /// Converts domain Routine entity to RoutineDto for API communication
  RoutineDto _routineToDto(Routine routine) {
    return RoutineDto(
      id: routine.id,
      name: routine.name,
      description: routine.description,
      userId: routine.userId,
      exercises: routine.exercises
          .map((exercise) => _routineExerciseToDto(exercise))
          .toList(),
      createdAt: routine.createdAt?.toIso8601String(),
    );
  }

  /// Converts domain RoutineExercise entity to RoutineExerciseDto for API communication
  RoutineExerciseDto _routineExerciseToDto(RoutineExercise exercise) {
    return RoutineExerciseDto(
      id: exercise.id,
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      orderIndex: exercise.orderIndex,
      sets: exercise.sets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
    );
  }
}

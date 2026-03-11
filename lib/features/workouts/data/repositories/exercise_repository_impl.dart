import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/exercise_remote_datasource.dart';

/// Implementation of ExerciseRepository that bridges datasource and domain
/// Handles API communication and transforms DTOs to entities
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseRemoteDatasource remoteDatasource;

  const ExerciseRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Exercise>> getExercises() async {
    try {
      // Get exercises from remote datasource
      final exerciseDtos = await remoteDatasource.getExercises();

      // Transform DTOs to entities before returning to domain layer
      return exerciseDtos.map((dto) => dto.toEntity()).toList();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
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
        throw const NetworkFailure('Exercise service not available');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to load exercises: ${e.toString()}');
    }
  }

  @override
  Future<Exercise?> getExerciseById(int id) async {
    try {
      // Validate input
      if (id <= 0) {
        throw const ValidationFailure('Valid exercise ID is required');
      }

      // Get exercise from remote datasource
      final exerciseDto = await remoteDatasource.getExerciseById(id);

      // Transform DTO to entity before returning to domain layer
      return exerciseDto?.toEntity();
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
        // Return null for not found exercises (valid case)
        return null;
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to load exercise: ${e.toString()}');
    }
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    try {
      // Validate input
      if (query.trim().isEmpty) {
        throw const ValidationFailure('Search query cannot be empty');
      }

      // Get exercises from remote datasource
      final exerciseDtos = await remoteDatasource.searchExercises(query.trim());

      // Transform DTOs to entities before returning to domain layer
      return exerciseDtos.map((dto) => dto.toEntity()).toList();
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
        throw const NetworkFailure('Exercise search service not available');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to search exercises: ${e.toString()}');
    }
  }
}

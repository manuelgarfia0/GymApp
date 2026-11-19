import 'dart:async';
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
    final result = await _execute<List<Exercise>>(
      () async {
        final exerciseDtos = await remoteDatasource.getExercises();
        return exerciseDtos.map((dto) => dto.toEntity()).toList();
      },
      fallbackPrefix: 'Failed to load exercises',
      notFoundMessage: 'Exercise service not available',
    );
    return result!;
  }

  @override
  Future<Exercise?> getExerciseById(int id) {
    return _execute<Exercise?>(
      () async {
        if (id <= 0) {
          throw const ValidationFailure('Valid exercise ID is required');
        }
        final exerciseDto = await remoteDatasource.getExerciseById(id);
        return exerciseDto?.toEntity();
      },
      fallbackPrefix: 'Failed to load exercise',
      nullOnNotFound: true,
    );
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final result = await _execute<List<Exercise>>(
      () async {
        if (query.trim().isEmpty) {
          throw const ValidationFailure('Search query cannot be empty');
        }
        final exerciseDtos = await remoteDatasource.searchExercises(
          query.trim(),
        );
        return exerciseDtos.map((dto) => dto.toEntity()).toList();
      },
      fallbackPrefix: 'Failed to search exercises',
      notFoundMessage: 'Exercise search service not available',
    );
    return result!;
  }

  Future<T?> _execute<T>(
    Future<T?> Function() action, {
    required String fallbackPrefix,
    String? notFoundMessage,
    bool nullOnNotFound = false,
  }) async {
    try {
      return await action();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on TimeoutException {
      throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('timeout') ||
          errorMessage.contains('tiempo de espera')) {
        throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
      } else if (errorMessage.contains('401') ||
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
        if (nullOnNotFound) return null;
        throw NetworkFailure(
          notFoundMessage ?? 'Exercise service not available',
        );
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      throw NetworkFailure('$fallbackPrefix: ${e.toString()}');
    }
  }
}

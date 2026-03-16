import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/workout_remote_datasource.dart';
import '../models/workout_dto.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDatasource remoteDatasource;

  const WorkoutRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<Workout>> getUserWorkouts(int userId) async {
    try {
      if (userId <= 0)
        throw const ValidationFailure('Valid user ID is required');
      final dtos = await remoteDatasource.getUserWorkouts(userId);
      return dtos.map((dto) => dto.toEntity()).toList();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to load workouts');
    }
  }

  @override
  Future<Workout?> getWorkoutById(int id) async {
    try {
      if (id <= 0)
        throw const ValidationFailure('Valid workout ID is required');
      final dto = await remoteDatasource.getWorkoutById(id);
      return dto?.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to load workout');
    }
  }

  @override
  Future<Workout> createWorkout(Workout workout) async {
    try {
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure('Workout name cannot be empty');
      }
      if (workout.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }
      final dto = _workoutToDto(workout);
      final createdDto = await remoteDatasource.createWorkout(dto);
      return createdDto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to create workout');
    }
  }

  @override
  Future<Workout> updateWorkout(Workout workout) async {
    try {
      if (workout.id == null || workout.id! <= 0) {
        throw const ValidationFailure(
          'Valid workout ID is required for update',
        );
      }
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure('Workout name cannot be empty');
      }
      final dto = _workoutToDto(workout);
      final updatedDto = await remoteDatasource.updateWorkout(dto);
      return updatedDto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to update workout');
    }
  }

  @override
  Future<Workout> endWorkout(int workoutId) async {
    try {
      if (workoutId <= 0) {
        throw const ValidationFailure('Valid workout ID is required');
      }
      final dto = await remoteDatasource.endWorkout(workoutId);
      return dto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to end workout');
    }
  }

  WorkoutDto _workoutToDto(Workout workout) {
    return WorkoutDto(
      id: workout.id,
      name: workout.name,
      notes: workout.notes,
      startTime: workout.startTime.toIso8601String(),
      endTime: workout.endTime?.toIso8601String(),
      userId: workout.userId,
      routineId: workout.routineId,
      sets: workout.sets.map((set) => _workoutSetToDto(set)).toList(),
    );
  }

  WorkoutSetDto _workoutSetToDto(WorkoutSet set) {
    return WorkoutSetDto(
      exerciseId: set.exerciseId,
      exerciseName: set.exerciseName,
      exerciseOrder: set.exerciseOrder,
      setNumber: set.setNumber,
      weight: set.weight,
      reps: set.reps,
      notes: set.notes,
      // CORRECCIÓN: enviamos isWarmup e isCompleted, eliminamos timestamp
      isWarmup: set.isWarmup,
      isCompleted: set.isCompleted,
    );
  }

  Failure _mapError(Object e, String fallbackMessage) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return const AuthenticationFailure('Session expired, please login again');
    } else if (msg.contains('403') || msg.contains('forbidden')) {
      return const AuthenticationFailure(
        'You are not authorized to perform this action',
      );
    } else if (msg.contains('404')) {
      return const NetworkFailure('Resource not found');
    } else if (msg.contains('400') || msg.contains('bad request')) {
      return const ValidationFailure('Invalid data provided');
    } else if (msg.contains('500') || msg.contains('server')) {
      return const NetworkFailure('Server error, please try again later');
    }
    return NetworkFailure('$fallbackMessage: ${e.toString()}');
  }
}

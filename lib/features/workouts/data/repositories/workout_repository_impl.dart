import 'dart:async';
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
  Future<List<Workout>> getUserWorkouts(int userId) {
    return _execute(() async {
      if (userId <= 0) {
        throw const ValidationFailure('Se requiere un ID de usuario válido');
      }
      final dtos = await remoteDatasource.getUserWorkouts(userId);
      return dtos.map((dto) => dto.toEntity()).toList();
    }, 'Error al cargar los entrenamientos');
  }

  @override
  Future<Workout?> getWorkoutById(int id) {
    return _execute(() async {
      if (id <= 0) {
        throw const ValidationFailure('Se requiere un ID de entrenamiento válido');
      }
      final dto = await remoteDatasource.getWorkoutById(id);
      return dto?.toEntity();
    }, 'Error al cargar el entrenamiento');
  }

  @override
  Future<Workout> createWorkout(Workout workout) {
    return _execute(() async {
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure(
          'El nombre del entrenamiento no puede estar vacío',
        );
      }
      if (workout.userId <= 0) {
        throw const ValidationFailure('Se requiere un ID de usuario válido');
      }
      final createdDto = await remoteDatasource.createWorkout(
        _workoutToDto(workout),
      );
      return createdDto.toEntity();
    }, 'Error al guardar el entrenamiento');
  }

  @override
  Future<Workout> updateWorkout(Workout workout) {
    return _execute(() async {
      if (workout.id == null || workout.id! <= 0) {
        throw const ValidationFailure(
          'Se requiere un ID de entrenamiento válido para actualizar',
        );
      }
      if (workout.name.trim().isEmpty) {
        throw const ValidationFailure(
          'El nombre del entrenamiento no puede estar vacío',
        );
      }
      final updatedDto = await remoteDatasource.updateWorkout(
        _workoutToDto(workout),
      );
      return updatedDto.toEntity();
    }, 'Error al actualizar el entrenamiento');
  }

  @override
  Future<bool> deleteWorkout(int id) {
    return _execute(() async {
      if (id <= 0) {
        throw const ValidationFailure('Se requiere un ID de entrenamiento válido');
      }
      return await remoteDatasource.deleteWorkout(id);
    }, 'Error al eliminar el entrenamiento');
  }

  @override
  Future<Workout> endWorkout(int workoutId) {
    return _execute(() async {
      if (workoutId <= 0) {
        throw const ValidationFailure('Se requiere un ID de entrenamiento válido');
      }
      final dto = await remoteDatasource.endWorkout(workoutId);
      return dto.toEntity();
    }, 'Error al finalizar el entrenamiento');
  }

  Future<T> _execute<T>(
    Future<T> Function() action,
    String fallbackMessage,
  ) async {
    try {
      return await action();
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on TimeoutException {
      throw const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } on http.ClientException {
      throw const NetworkFailure(
        'Tiempo de espera agotado al conectar con el servidor',
      );
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, fallbackMessage);
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
      isWarmup: set.isWarmup,
      isCompleted: set.isCompleted,
    );
  }

  Failure _mapError(Object e, String fallbackMessage) {
    final raw = e
        .toString()
        .replaceFirst(RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'), '')
        .trim();
    final msg = raw.toLowerCase();

    if (msg.contains('timeout') || msg.contains('tiempo de espera')) {
      return const NetworkFailure(NetworkFailure.serverWakingTimeoutMessage);
    } else if (msg.contains('401') || msg.contains('unauthorized')) {
      return const AuthenticationFailure('Sesión expirada. Por favor, inicia sesión de nuevo');
    } else if (msg.contains('403') || msg.contains('forbidden')) {
      return const AuthenticationFailure('No tienes permisos para realizar esta acción');
    } else if (msg.contains('404')) {
      return NetworkFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Entrenamiento no encontrado');
    } else if (msg.contains('400') || msg.contains('bad request')) {
      return ValidationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Datos del entrenamiento no válidos');
    } else if (msg.contains('500') || msg.contains('server')) {
      return const NetworkFailure('Error en el servidor. Por favor, inténtalo más tarde');
    }
    return NetworkFailure(raw.isNotEmpty ? raw : fallbackMessage);
  }
}

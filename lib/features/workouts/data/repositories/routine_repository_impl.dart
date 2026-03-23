// lib/features/workouts/data/repositories/routine_repository_impl.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/routine_remote_datasource.dart';
import '../models/routine_dto.dart';

/// Implementación del repositorio de rutinas.
///
/// Traduce entidades de dominio a DTOs para la capa de datos y viceversa.
/// Centraliza el mapeo de errores de infraestructura a [Failure] de dominio.
class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineRemoteDatasource remoteDatasource;

  const RoutineRepositoryImpl({required this.remoteDatasource});

  // ── Public API ────────────────────────────────────────────────────────────

  @override
  Future<List<Routine>> getUserRoutines(int userId) async {
    try {
      if (userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }
      final dtos = await remoteDatasource.getUserRoutines(userId);
      return dtos.map((d) => d.toEntity()).toList();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to load routines');
    }
  }

  @override
  Future<Routine?> getRoutineById(int id) async {
    try {
      if (id <= 0) {
        throw const ValidationFailure('Valid routine ID is required');
      }
      final dto = await remoteDatasource.getRoutineById(id);
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
      throw _mapError(e, 'Failed to load routine');
    }
  }

  @override
  Future<Routine> createRoutine(Routine routine) async {
    try {
      _validateRoutine(routine);
      final dto = _toDto(routine);
      final created = await remoteDatasource.createRoutine(dto);
      return created.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to create routine');
    }
  }

  @override
  Future<Routine> updateRoutine(Routine routine) async {
    try {
      if (routine.id == null || routine.id! <= 0) {
        throw const ValidationFailure(
          'Valid routine ID is required for update',
        );
      }
      _validateRoutine(routine);
      final dto = _toDto(routine);
      final updated = await remoteDatasource.updateRoutine(dto);
      return updated.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to update routine');
    }
  }

  @override
  Future<bool> deleteRoutine(int id) async {
    try {
      if (id <= 0) {
        throw const ValidationFailure('Valid routine ID is required');
      }
      return await remoteDatasource.deleteRoutine(id);
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Failed to delete routine');
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  void _validateRoutine(Routine routine) {
    if (routine.name.trim().isEmpty) {
      throw const ValidationFailure('Routine name cannot be empty');
    }
    if (routine.userId <= 0) {
      throw const ValidationFailure('Valid user ID is required');
    }
    if (routine.exercises.isEmpty) {
      throw const ValidationFailure(
        'Routine must contain at least one exercise',
      );
    }
  }

  // ── DTO mapping ───────────────────────────────────────────────────────────

  /// Convierte una entidad de dominio [Routine] al DTO de red.
  ///
  /// Incluye [targetWeight] en cada ejercicio para que [ActiveWorkoutScreen]
  /// pueda pre-rellenar el peso cuando no existe historial previo.
  RoutineDto _toDto(Routine routine) {
    return RoutineDto(
      id: routine.id,
      name: routine.name.trim(),
      description: routine.description?.trim(),
      userId: routine.userId,
      exercises: routine.exercises.map((e) => _exerciseToDto(e)).toList(),
      createdAt: routine.createdAt?.toIso8601String(),
    );
  }

  RoutineExerciseDto _exerciseToDto(RoutineExercise exercise) {
    return RoutineExerciseDto(
      id: exercise.id,
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      orderIndex: exercise.orderIndex,
      sets: exercise.sets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      targetWeight: exercise.targetWeight, // ← campo añadido
      notes: exercise.notes,
    );
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  Failure _mapError(Object e, String prefix) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return const AuthenticationFailure('Session expired, please login again');
    } else if (msg.contains('403') || msg.contains('forbidden')) {
      return const AuthenticationFailure(
        'You are not authorized to perform this action',
      );
    } else if (msg.contains('404')) {
      return const NetworkFailure('Routine not found');
    } else if (msg.contains('400') || msg.contains('bad request')) {
      return const ValidationFailure('Invalid routine data provided');
    } else if (msg.contains('409') || msg.contains('conflict')) {
      return const ValidationFailure('A routine with this name already exists');
    } else if (msg.contains('500') || msg.contains('server')) {
      return const NetworkFailure('Server error, please try again later');
    }
    return NetworkFailure('$prefix: ${e.toString()}');
  }
}

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
        throw const ValidationFailure('Se requiere un ID de usuario válido');
      }
      final dtos = await remoteDatasource.getUserRoutines(userId);
      return dtos.map((d) => d.toEntity()).toList();
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on http.ClientException {
      throw const NetworkFailure('Tiempo de espera agotado al conectar con el servidor');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Error al cargar las rutinas');
    }
  }

  @override
  Future<Routine?> getRoutineById(int id) async {
    try {
      if (id <= 0) {
        throw const ValidationFailure('Se requiere un ID de rutina válido');
      }
      final dto = await remoteDatasource.getRoutineById(id);
      return dto?.toEntity();
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on http.ClientException {
      throw const NetworkFailure('Tiempo de espera agotado al conectar con el servidor');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Error al cargar la rutina');
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
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on http.ClientException {
      throw const NetworkFailure('Tiempo de espera agotado al conectar con el servidor');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Error al crear la rutina');
    }
  }

  @override
  Future<Routine> updateRoutine(Routine routine) async {
    try {
      if (routine.id == null || routine.id! <= 0) {
        throw const ValidationFailure('Se requiere un ID de rutina válido para actualizar');
      }
      _validateRoutine(routine);
      final dto = _toDto(routine);
      final updated = await remoteDatasource.updateRoutine(dto);
      return updated.toEntity();
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on http.ClientException {
      throw const NetworkFailure('Tiempo de espera agotado al conectar con el servidor');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Error al actualizar la rutina');
    }
  }

  @override
  Future<bool> deleteRoutine(int id) async {
    try {
      if (id <= 0) {
        throw const ValidationFailure('Se requiere un ID de rutina válido');
      }
      return await remoteDatasource.deleteRoutine(id);
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on http.ClientException {
      throw const NetworkFailure('Tiempo de espera agotado al conectar con el servidor');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      throw _mapError(e, 'Error al eliminar la rutina');
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  void _validateRoutine(Routine routine) {
    if (routine.name.trim().isEmpty) {
      throw const ValidationFailure('El nombre de la rutina no puede estar vacío');
    }
    if (routine.userId <= 0) {
      throw const ValidationFailure('Se requiere un ID de usuario válido');
    }
    if (routine.exercises.isEmpty) {
      throw const ValidationFailure('La rutina debe contener al menos un ejercicio');
    }
  }

  // ── DTO mapping ───────────────────────────────────────────────────────────

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
      targetWeight: exercise.targetWeight,
      notes: exercise.notes,
    );
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  Failure _mapError(Object e, String prefix) {
    final raw = e
        .toString()
        .replaceFirst(RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'), '')
        .trim();
    final msg = raw.toLowerCase();

    if (msg.contains('401') || msg.contains('unauthorized')) {
      return const AuthenticationFailure('Sesión expirada. Por favor, inicia sesión de nuevo');
    } else if (msg.contains('403') || msg.contains('forbidden')) {
      return const AuthenticationFailure('No tienes permisos para realizar esta acción');
    } else if (msg.contains('404') || msg.contains('not found')) {
      return NetworkFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Rutina no encontrada');
    } else if (msg.contains('409') || msg.contains('conflict')) {
      return ValidationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Ya existe una rutina con ese nombre');
    } else if (msg.contains('400') || msg.contains('bad request')) {
      return ValidationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Datos de rutina no válidos');
    } else if (msg.contains('500') || msg.contains('server')) {
      return const NetworkFailure('Error en el servidor. Por favor, inténtalo más tarde');
    }
    return NetworkFailure(raw.isNotEmpty ? raw : prefix);
  }
}

// lib/features/profile/data/repositories/profile_repository_impl.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/session/session_service.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_dto.dart';

/// Implementación del repositorio de perfil.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;
  final SessionService sessionService;

  ProfileRepositoryImpl({
    required this.remoteDatasource,
    required this.sessionService,
  });

  @override
  Future<UserProfile?> getUserProfile(int userId) async {
    try {
      if (userId <= 0) {
        throw const ValidationFailure('Se requiere un ID de usuario válido');
      }

      final dto = await remoteDatasource.getUserProfile(userId);
      return dto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No hay conexión a internet disponible');
    } on http.ClientException {
      throw const NetworkFailure('Tiempo de espera agotado al conectar con el servidor');
    } on FormatException {
      throw const NetworkFailure('Formato de respuesta del servidor no válido');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        throw const AuthenticationFailure('Sesión expirada. Por favor, inicia sesión de nuevo');
      } else if (msg.contains('403') || msg.contains('forbidden')) {
        throw const AuthenticationFailure('No tienes permisos para ver este perfil');
      } else if (msg.contains('404')) {
        return null;
      } else if (msg.contains('500') || msg.contains('server')) {
        throw const NetworkFailure('Error en el servidor. Por favor, inténtalo más tarde');
      }
      return null;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    try {
      if (userProfile.userId <= 0) {
        throw const ValidationFailure('Se requiere un ID de usuario válido');
      }

      final dto = UserProfileDto.fromEntity(userProfile);
      final updated = await remoteDatasource.updateUserProfile(dto);
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
      final raw = e
          .toString()
          .replaceFirst(RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'), '')
          .trim();
      final msg = raw.toLowerCase();

      if (msg.contains('401') || msg.contains('unauthorized')) {
        throw const AuthenticationFailure('Sesión expirada. Por favor, inicia sesión de nuevo');
      } else if (msg.contains('403') || msg.contains('forbidden')) {
        throw const AuthenticationFailure('No tienes permisos para actualizar este perfil');
      } else if (msg.contains('400') || msg.contains('bad request')) {
        throw ValidationFailure(raw.isNotEmpty && !msg.contains('statuscode') ? raw : 'Datos de perfil no válidos');
      } else if (msg.contains('404')) {
        throw const ValidationFailure('Perfil no encontrado');
      } else if (msg.contains('500') || msg.contains('server')) {
        throw const NetworkFailure('Error en el servidor. Por favor, inténtalo más tarde');
      }
      throw NetworkFailure(raw.isNotEmpty ? raw : 'Error al actualizar el perfil');
    }
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = await sessionService.getUserId();
      if (userId == null || userId <= 0) return null;

      return await getUserProfile(userId);
    } catch (_) {
      return null;
    }
  }
}

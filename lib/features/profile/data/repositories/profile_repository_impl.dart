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
///
/// Recibe [SessionService] por constructor injection para obtener
/// el userId del usuario activo directamente desde el JWT,
/// eliminando la dependencia de [SharedPreferences].
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
        throw const ValidationFailure('Valid user ID is required');
      }

      final dto = await remoteDatasource.getUserProfile(userId);
      return dto.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (msg.contains('403') || msg.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (msg.contains('404')) {
        return null;
      } else if (msg.contains('500') || msg.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }
      return null;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    try {
      if (userProfile.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      final dto = UserProfileDto.fromEntity(userProfile);
      final updated = await remoteDatasource.updateUserProfile(dto);
      return updated.toEntity();
    } on SocketException {
      throw const NetworkFailure('No internet connection available');
    } on http.ClientException {
      throw const NetworkFailure(
        'Request timed out, please check your connection',
      );
    } on FormatException {
      throw const NetworkFailure('Invalid response format from server');
    } on ValidationFailure {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        throw const AuthenticationFailure(
          'Session expired, please login again',
        );
      } else if (msg.contains('403') || msg.contains('forbidden')) {
        throw const AuthenticationFailure(
          'You are not authorized to perform this action',
        );
      } else if (msg.contains('400') || msg.contains('bad request')) {
        throw const ValidationFailure('Invalid profile data provided');
      } else if (msg.contains('404')) {
        throw const ValidationFailure('Profile not found');
      } else if (msg.contains('500') || msg.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }
      throw NetworkFailure('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      // El userId se obtiene del JWT a través de [SessionService],
      // sin necesidad de [SharedPreferences] como almacén auxiliar.
      final userId = await sessionService.getUserId();
      if (userId == null || userId <= 0) return null;

      return await getUserProfile(userId);
    } catch (_) {
      return null;
    }
  }
}

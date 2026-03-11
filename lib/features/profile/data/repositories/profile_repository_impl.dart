import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_dto.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;

  ProfileRepositoryImpl(this.remoteDatasource);

  @override
  Future<UserProfile?> getUserProfile(int userId) async {
    try {
      // Validate input
      if (userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      final userProfileDto = await remoteDatasource.getUserProfile(userId);
      return userProfileDto.toEntity();
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
        // Return null for profile not found (valid case)
        return null;
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Return null for other errors (graceful degradation)
      return null;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    try {
      // Validate input
      if (userProfile.userId <= 0) {
        throw const ValidationFailure('Valid user ID is required');
      }

      final userProfileDto = UserProfileDto.fromEntity(userProfile);
      final updatedDto = await remoteDatasource.updateUserProfile(
        userProfileDto,
      );
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
        throw const ValidationFailure('Invalid profile data provided');
      } else if (errorMessage.contains('404')) {
        throw const ValidationFailure('Profile not found');
      } else if (errorMessage.contains('500') ||
          errorMessage.contains('server')) {
        throw const NetworkFailure('Server error, please try again later');
      }

      // Default network failure for unknown errors
      throw NetworkFailure('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      // Get current user ID from shared preferences (consistent with current implementation)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null || userId == 0) return null;

      return await getUserProfile(userId);
    } catch (e) {
      // For getCurrentUserProfile, we return null on any error (graceful degradation)
      return null;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/user_profile_dto.dart';

abstract class ProfileRemoteDatasource {
  /// Fetches user profile from the API by user ID
  Future<UserProfileDto> getUserProfile(int userId);

  /// Updates user profile via API
  Future<UserProfileDto> updateUserProfile(UserProfileDto userProfile);

  /// Changes the authenticated user password after verifying the current one
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  );

  /// Permanently deletes the authenticated user account
  Future<void> deleteAccount(int userId, String password);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final ApiClient apiClient;

  ProfileRemoteDatasourceImpl(this.apiClient);

  @override
  Future<UserProfileDto> getUserProfile(int userId) async {
    try {
      final response = await apiClient.get(
        Uri.parse('${ApiConstants.usersEndpoint}/$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return UserProfileDto.fromJson(data);
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('Network error while fetching user profile: $e');
    }
  }

  @override
  Future<UserProfileDto> updateUserProfile(UserProfileDto userProfile) async {
    try {
      final response = await apiClient.put(
        Uri.parse('${ApiConstants.usersEndpoint}/${userProfile.id}'),
        body: jsonEncode(userProfile.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return UserProfileDto.fromJson(data);
      } else {
        final serverMsg = _extractServerMessage(
          utf8.decode(response.bodyBytes),
        );
        throw Exception(
          serverMsg != null
              ? '$serverMsg (${response.statusCode})'
              : 'Failed to update user profile: ${response.statusCode}',
        );
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (e is Exception && !e.toString().startsWith('Exception: Network')) {
        rethrow;
      }
      throw Exception('Network error while updating user profile: $e');
    }
  }

  @override
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await apiClient.put(
        Uri.parse('${ApiConstants.usersEndpoint}/$userId/password'),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      final serverMsg = _extractServerMessage(
        utf8.decode(response.bodyBytes),
      );
      throw Exception(
        serverMsg != null
            ? '$serverMsg (${response.statusCode})'
            : 'Failed to change password: ${response.statusCode}',
      );
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (e is Exception && !e.toString().startsWith('Exception: Network')) {
        rethrow;
      }
      throw Exception('Network error while changing password: $e');
    }
  }

  @override
  Future<void> deleteAccount(int userId, String password) async {
    try {
      final response = await apiClient.post(
        Uri.parse('${ApiConstants.usersEndpoint}/$userId/delete'),
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      final serverMsg = _extractServerMessage(
        utf8.decode(response.bodyBytes),
      );
      throw Exception(
        serverMsg != null
            ? '$serverMsg (${response.statusCode})'
            : 'Failed to delete account: ${response.statusCode}',
      );
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (e is Exception && !e.toString().startsWith('Exception: Network')) {
        rethrow;
      }
      throw Exception('Network error while deleting account: $e');
    }
  }

  String? _extractServerMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final fieldErrors = decoded['fieldErrors'];
      if (fieldErrors is Map && fieldErrors.isNotEmpty) {
        return fieldErrors.values.join(', ');
      }
      final msg = decoded['message'] as String?;
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      final err = decoded['error'] as String?;
      return (err != null && err.trim().isNotEmpty) ? err.trim() : null;
    } catch (_) {
      return null;
    }
  }
}

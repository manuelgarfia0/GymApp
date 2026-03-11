import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/user_profile_dto.dart';

abstract class ProfileRemoteDatasource {
  /// Fetches user profile from the API by user ID
  Future<UserProfileDto> getUserProfile(int userId);

  /// Updates user profile via API
  Future<UserProfileDto> updateUserProfile(UserProfileDto userProfile);
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
        throw Exception(
          'Failed to update user profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error while updating user profile: $e');
    }
  }
}

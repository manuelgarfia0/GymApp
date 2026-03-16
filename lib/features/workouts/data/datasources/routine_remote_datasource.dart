import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/routine_dto.dart';

abstract class RoutineRemoteDatasource {
  Future<List<RoutineDto>> getUserRoutines(int userId);
  Future<RoutineDto?> getRoutineById(int id);
  Future<RoutineDto> createRoutine(RoutineDto routine);
  Future<RoutineDto> updateRoutine(RoutineDto routine);
  Future<bool> deleteRoutine(int id);
}

class RoutineRemoteDatasourceImpl implements RoutineRemoteDatasource {
  final ApiClient apiClient;

  const RoutineRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<RoutineDto>> getUserRoutines(int userId) async {
    try {
      // CORRECCIÓN: el backend expone GET /api/routines/user/{userId} (path variable)
      // El frontend anterior usaba query param ?userId= que daba 404
      final uri = Uri.parse('${ApiConstants.routinesEndpoint}/user/$userId');

      print('🔍 Routine API: Calling ${uri.toString()}');
      final response = await apiClient.get(uri);
      print('🔍 Routine API: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) => RoutineDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get user routines';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<RoutineDto?> getRoutineById(int id) async {
    try {
      final response = await apiClient.get(
        Uri.parse('${ApiConstants.routinesEndpoint}/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RoutineDto.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to get routine',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<RoutineDto> createRoutine(RoutineDto routine) async {
    try {
      final response = await apiClient.post(
        Uri.parse(ApiConstants.routinesEndpoint),
        body: jsonEncode(routine.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RoutineDto.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to create routine',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<RoutineDto> updateRoutine(RoutineDto routine) async {
    try {
      final response = await apiClient.put(
        Uri.parse('${ApiConstants.routinesEndpoint}/${routine.id}'),
        body: jsonEncode(routine.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RoutineDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Routine not found');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to update routine',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<bool> deleteRoutine(int id) async {
    try {
      final response = await apiClient.delete(
        Uri.parse('${ApiConstants.routinesEndpoint}/$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] as String? ?? 'Failed to delete routine',
        );
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }
}

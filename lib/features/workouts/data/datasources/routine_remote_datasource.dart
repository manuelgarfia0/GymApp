import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/routine_dto.dart';

/// Abstract interface for routine remote data source
abstract class RoutineRemoteDatasource {
  /// Retrieves all routines for a specific user from the API
  /// Returns list of RoutineDto belonging to the user
  /// Throws exception on failure
  Future<List<RoutineDto>> getUserRoutines(int userId);

  /// Retrieves a specific routine by its ID from the API
  /// Returns RoutineDto if found, null otherwise
  /// Throws exception on failure
  Future<RoutineDto?> getRoutineById(int id);

  /// Creates a new routine via the API
  /// Returns the created RoutineDto with assigned ID
  /// Throws exception on failure
  Future<RoutineDto> createRoutine(RoutineDto routine);

  /// Updates an existing routine via the API
  /// Returns the updated RoutineDto
  /// Throws exception on failure
  Future<RoutineDto> updateRoutine(RoutineDto routine);

  /// Deletes a routine by its ID via the API
  /// Returns true if deletion was successful
  /// Throws exception on failure
  Future<bool> deleteRoutine(int id);
}

/// Implementation of RoutineRemoteDatasource using HTTP API
class RoutineRemoteDatasourceImpl implements RoutineRemoteDatasource {
  final ApiClient apiClient;

  const RoutineRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<RoutineDto>> getUserRoutines(int userId) async {
    try {
      final uri = Uri.parse(
        ApiConstants.routinesEndpoint,
      ).replace(queryParameters: {'userId': userId.toString()});

      print('🔍 Routine API: Calling ${uri.toString()}');
      final response = await apiClient.get(uri);
      print('🔍 Routine API: Response status ${response.statusCode}');
      print('🔍 Routine API: Response body ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        print('🔍 Routine API: Parsed ${data.length} routines');
        return data
            .map((json) => RoutineDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get user routines';
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      print('🔍 Routine API: SocketException - $e');
      throw Exception('No internet connection');
    } on FormatException catch (e) {
      print('🔍 Routine API: FormatException - $e');
      throw Exception('Invalid response format');
    } catch (e) {
      print('🔍 Routine API: Unexpected error - $e');
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
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to get routine';
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
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Invalid routine data';
        throw Exception(errorMessage);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to create routine';
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
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Invalid routine data';
        throw Exception(errorMessage);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to update routine';
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
        final errorMessage =
            errorData?['message'] as String? ?? 'Failed to delete routine';
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
}

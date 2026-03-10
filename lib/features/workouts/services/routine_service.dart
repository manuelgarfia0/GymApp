import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/features/workouts/models/routine.dart';

class RoutineService {
  final String baseUrl = 'http://10.0.2.2:8080/routines';

  Future<List<RoutineDTO>> getUserRoutines(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => RoutineDTO.fromJson(json)).toList();
      } else {
        print('Error fetching routines: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Routine connection error: $e');
      return [];
    }
  }

  Future<bool> saveRoutine(RoutineDTO routine) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(routine.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // --- NUEVO MÉTODO PARA ACTUALIZAR RUTINAS ---
  Future<bool> updateRoutine(int id, RoutineDTO routine) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(routine.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Update routine error: $e');
      return false;
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/features/workouts/models/workout.dart';

class WorkoutService {
  final String baseUrl = 'http://10.0.2.2:8080/workouts';

  // Cambiamos WorkoutRequest por WorkoutDTO aquí
  Future<bool> saveWorkout(WorkoutDTO request) async {
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
        body: jsonEncode(request.toJson()), // Convertimos el DTO a JSON
      );

      // Si el servidor nos devuelve 200 OK o 201 Created
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Imprimimos el error exacto que nos devuelve Spring Boot para poder investigar si falla
        print('Error al guardar: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de conexión: $e');
      return false;
    }
  }
  
  Future<List<WorkoutDTO>> getUserWorkouts(int userId) async {
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
        // Al usar fromJson() ahora pilla automáticamente TODAS las series que vengan del backend
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => WorkoutDTO.fromJson(json)).toList();
      } else {
        print('Error fetching history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('History connection error: $e');
      return [];
    }
  }
}
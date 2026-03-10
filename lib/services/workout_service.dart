import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/models/workout.dart';

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
}
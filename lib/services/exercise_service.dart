import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/models/exercise.dart';

class ExerciseService {
  final String baseUrl = 'http://10.0.2.2:8080/exercises';

  Future<List<Exercise>> getExercises() async {
    // 1. Recuperamos el token de la memoria
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('No token available. Please log in.');
    }

    try {
      // 2. Hacemos la petición GET enviando el token en el Header 'Authorization'
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ¡Aquí va la llave mágica!
        },
      );

      // 3. Si la respuesta es OK (200)
      if (response.statusCode == 200) {
        // En Dart, como la API devuelve un Array [ {}, {} ], usamos un List
        List<dynamic> body = jsonDecode(response.body);
        
        // Convertimos cada objeto JSON en un objeto Exercise
        List<Exercise> exercises = body.map((dynamic item) => Exercise.fromJson(item)).toList();
        
        return exercises;
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/models/user.dart';

class UserService {
  final String baseUrl = 'http://10.0.2.2:8080/api/users';

  // Obtenemos el perfil del usuario mediante su ID
  Future<UserDTO?> getUserProfile(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Si la petición es exitosa, decodificamos el JSON y devolvemos el DTO
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserDTO.fromJson(data);
      } else {
        print('Error fetching user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('User connection error: $e');
      return null;
    }
  }
}
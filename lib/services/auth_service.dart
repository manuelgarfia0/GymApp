import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ATENCIÓN: Como estamos en un emulador de Android, no podemos usar 'localhost'
  // El emulador de Android usa '10.0.2.2' para referirse al 'localhost' de tu ordenador físico.
  final String baseUrl = 'http://10.0.2.2:8080/api/auth';

  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      // Si la API responde con 200 OK
      if (response.statusCode == 200) {
        // Extraemos el cuerpo del JSON que nos devuelve Spring Boot
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Devolvemos el Token JWT
        return responseData['token'];
      } else {
        // Si el usuario/contraseña está mal (403 o 401)
        print('Error en login: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error de conexión con la API: $e');
      return null;
    }
  }
}
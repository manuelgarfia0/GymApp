import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // NUEVA IMPORTACIÓN
import 'package:gym_app/features/home/screens/home_screen.dart';
import 'package:gym_app/features/auth/services/auth_service.dart';
import 'package:gym_app/core/storage/secure_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    // 1. Iniciamos la carga
    setState(() { _isLoading = true; });

    try {
      // 2. Delegamos la lógica de red al AuthService (él maneja la URL y los errores)
      final authService = AuthService();
      final token = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      // 3. Decodificamos el token para sacar el ID
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      int userId = decodedToken['id'];

      // 4. Guardamos todo de forma SEGURA (usando el servicio que creamos)
      final storageService = SecureStorageService();
      await storageService.saveToken(token);
      
      // Nota: SecureStorage guarda Strings. Si necesitas guardar el ID, 
      // tendrías que añadir un método 'saveUserId(String id)' en tu SecureStorageService.
      // await storageService.saveUserId(userId.toString()); 

      // 5. Navegamos al Home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      
    } catch (e) {
      // 6. Si el AuthService lanza una excepción (ej. "Invalid password"), la mostramos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 7. Usamos finally para asegurarnos de que el botón siempre vuelva a su estado normal, 
      // falle o no la petición.
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 32),
              const Text(
                'Gym Tracker',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.blueAccent)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _login,
                        child: const Text('LOG IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
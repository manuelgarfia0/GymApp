import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_diagnostics.dart';
import '../../../home/screens/home_screen.dart';
import '../../domain/use_cases/login_user.dart';

class LoginScreen extends StatefulWidget {
  final LoginUser loginUseCase;

  const LoginScreen({super.key, required this.loginUseCase});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _runDiagnostics() async {
    // Ejecutar diagnósticos de red
    await NetworkDiagnostics.testConnectivity();

    // Test específico de Spring Boot
    await NetworkDiagnostics.testSpringBootHealth();

    // Si hay credenciales, probar login
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      await NetworkDiagnostics.testLogin(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  Future<void> _login() async {
    // 1. Iniciar estado de carga
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Iniciando proceso de login...');

      // 2. Usar el caso de uso LoginUser en lugar de AuthService
      final user = await widget.loginUseCase.call(
        _usernameController.text,
        _passwordController.text,
      );

      print('✅ Login exitoso! Usuario: ${user.username}');

      // 3. Navegar a Home después del login exitoso
      // El caso de uso maneja el almacenamiento del token internamente vía repositorio
      if (mounted) {
        print('🏠 Navegando a HomeScreen...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthenticationFailure catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      // Manejar errores específicos de autenticación con mensajes amigables
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on NetworkFailure catch (e) {
      print('❌ Error de red: ${e.message}');
      // Manejar errores relacionados con la red
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _login,
            ),
          ),
        );
      }
    } on ValidationFailure catch (e) {
      print('❌ Error de validación: ${e.message}');
      // Manejar errores de validación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
      // Manejar cualquier otro error inesperado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // 5. Resetear estado de carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
              const Icon(
                Icons.fitness_center,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              const Text(
                'Gym Tracker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'LOG IN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              // Botón temporal para diagnósticos
              TextButton(
                onPressed: _runDiagnostics,
                child: const Text(
                  'Run Network Diagnostics',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              // Botón para probar login real
              TextButton(
                onPressed: () async {
                  if (_usernameController.text.isNotEmpty &&
                      _passwordController.text.isNotEmpty) {
                    await NetworkDiagnostics.testLogin(
                      _usernameController.text,
                      _passwordController.text,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter username and password first'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Test Login with Credentials',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '🎉 API Connection Successful! 🎉',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Login endpoint working ✅ JWT tokens ✅',
                style: TextStyle(color: Colors.green, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

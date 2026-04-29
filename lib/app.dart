import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/auth_dependencies.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progressive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthCheckScreen(),
    );
  }
}

/// Pantalla invisible que decide si el usuario va al Home o al Login.
/// Verifica que el token exista Y no esté expirado antes de navegar al Home.
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storageService = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storageService.readToken();

    // Pequeño delay para que se vea el splash
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // CORRECCIÓN: antes solo comprobaba si el token existía, sin verificar si
    // estaba expirado. Un token expirado enviaba al usuario al HomeScreen
    // donde todas las llamadas API fallaban con 401.
    final bool hasValidToken = token != null &&
        token.isNotEmpty &&
        !JwtDecoder.isExpired(token);

    if (!hasValidToken && token != null) {
      // Token existe pero expirado — limpiarlo para no acumularlo
      await _storageService.deleteToken();
    }

    if (!mounted) return;

    if (hasValidToken) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(loginUseCase: AuthDependencies.loginUseCase),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/IconoProgressive.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
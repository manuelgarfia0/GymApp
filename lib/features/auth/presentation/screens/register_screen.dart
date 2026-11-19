import 'package:flutter/material.dart';
import '../../../../core/di/core_dependencies.dart';
import '../../../../core/errors/failures.dart';
import '../../../home/screens/home_screen.dart';
import '../../domain/use_cases/register_user.dart';

class RegisterScreen extends StatefulWidget {
  final RegisterUser registerUseCase;

  const RegisterScreen({super.key, required this.registerUseCase});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _selectedLanguage = 'es';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatDateIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDateDisplay(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$day/$m/${d.year}';
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: _selectedBirthDate ?? DateTime(now.year - 22, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (firstName.isEmpty) {
      _showError('Introduce tu nombre', color: Colors.amber);
      return;
    }

    if (lastName.isEmpty) {
      _showError('Introduce tus apellidos', color: Colors.amber);
      return;
    }

    if (_selectedBirthDate == null) {
      _showError('Selecciona tu fecha de nacimiento', color: Colors.amber);
      return;
    }

    if (password != confirm) {
      _showError('Las contraseñas no coinciden', color: Colors.amber);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.registerUseCase.call(
        username,
        email,
        password,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _formatDateIso(_selectedBirthDate!),
        languagePreference: _selectedLanguage,
      );

      if (mounted) {
        CoreDependencies.permissionsService.resetSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on ValidationFailure catch (e) {
      if (mounted) _showError(e.message, color: Colors.amber);
    } on NetworkFailure catch (e) {
      if (mounted) _showError(e.message, color: Colors.orange, retry: true);
    } on AuthenticationFailure catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst(RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'), '')
          .trim();
      if (mounted) {
        _showError(cleanMsg.isNotEmpty ? cleanMsg : 'Error al registrar la cuenta. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(
    String message, {
    Color color = Colors.red,
    bool retry = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        action: retry
            ? SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _register,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/IconoProgressive.png',
                  width: 110,
                  height: 110,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comienza a seguir tu progreso',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _firstNameController,
                      label: 'Nombre',
                      icon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _lastNameController,
                      label: 'Apellidos',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBirthDateField(),
              const SizedBox(height: 16),
              _buildLanguageSelector(),
              const SizedBox(height: 16),
              _buildField(
                controller: _usernameController,
                label: 'Usuario',
                icon: Icons.alternate_email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _passwordController,
                label: 'Contraseña (mínimo 8 caracteres)',
                icon: Icons.lock,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _confirmPasswordController,
                label: 'Confirmar contraseña',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
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
                        onPressed: _register,
                        child: const Text(
                          'CREAR CUENTA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    final hasDate = _selectedBirthDate != null;
    final labelText = hasDate
        ? _formatDateDisplay(_selectedBirthDate!)
        : 'Fecha de nacimiento';

    return InkWell(
      onTap: _pickBirthDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          labelText: hasDate ? 'Fecha de nacimiento' : null,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.cake_outlined, color: Colors.grey),
          suffixIcon: const Icon(
            Icons.calendar_month_outlined,
            color: Colors.blueAccent,
            size: 20,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          labelText,
          style: TextStyle(
            color: hasDate ? Colors.white : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.language_rounded, color: Colors.grey),
          const SizedBox(width: 12),
          const Text(
            'Idioma',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const Spacer(),
          _LanguageOption(
            label: 'Español',
            selected: _selectedLanguage == 'es',
            onTap: () => setState(() => _selectedLanguage = 'es'),
          ),
          const SizedBox(width: 8),
          _LanguageOption(
            label: 'English',
            selected: _selectedLanguage == 'en',
            onTap: () => setState(() => _selectedLanguage = 'en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueAccent
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

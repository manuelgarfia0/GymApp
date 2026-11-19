import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/core_dependencies.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/use_cases/update_user_profile.dart';

/// Pantalla para editar los datos personales, idioma y privacidad del perfil.
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final UpdateUserProfile updateUserProfileUseCase;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.updateUserProfileUseCase,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  DateTime? _birthDate;
  bool _clearBirthDate = false;
  late String _selectedLanguage;
  late bool _publicProfile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.profile.lastName ?? '',
    );
    _birthDate = widget.profile.dateOfBirth;
    final rawLang = (widget.profile.languagePreference ?? 'es').toLowerCase();
    _selectedLanguage = rawLang == 'en' ? 'en' : 'es';
    _publicProfile = widget.profile.publicProfile;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String _formatDateDisplay(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: _birthDate ?? DateTime(now.year - 22, 1, 1),
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
      setState(() {
        _birthDate = picked;
        _clearBirthDate = false;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty) {
      _showMessage('Introduce tu nombre', color: Colors.amber);
      return;
    }

    if (lastName.isEmpty) {
      _showMessage('Introduce tus apellidos', color: Colors.amber);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = widget.profile.copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _birthDate,
        clearDateOfBirth: _birthDate == null && _clearBirthDate,
        languagePreference: _selectedLanguage,
        publicProfile: _publicProfile,
      );

      final saved = await widget.updateUserProfileUseCase(updated);
      unawaited(
        CoreDependencies.settingsService.setLanguageCode(_selectedLanguage),
      );
      if (mounted) {
        Navigator.pop(context, saved);
      }
    } on ValidationFailure catch (e) {
      if (mounted) _showMessage(e.message, color: Colors.amber);
    } on AuthenticationFailure catch (e) {
      if (mounted) _showMessage(e.message, color: Colors.red);
    } on NetworkFailure catch (e) {
      if (mounted) _showMessage(e.message, color: Colors.orange);
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst(
            RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'),
            '',
          )
          .trim();
      if (mounted) {
        _showMessage(
          cleanMsg.isNotEmpty
              ? cleanMsg
              : 'No se pudo actualizar el perfil. Inténtalo de nuevo.',
          color: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color == Colors.amber ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.scaffoldBg(context);
    final cardBg = AppTheme.cardBg(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, size: 46, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '@${widget.profile.username}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.profile.email,
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              fieldKey: const Key('edit_profile_first_name'),
              controller: _firstNameController,
              label: 'Nombre',
              icon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              fieldKey: const Key('edit_profile_last_name'),
              controller: _lastNameController,
              label: 'Apellidos',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            _buildBirthDateField(),
            const SizedBox(height: 16),
            _buildLanguageSelector(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: SwitchListTile(
                key: const Key('edit_profile_public_switch'),
                value: _publicProfile,
                activeThumbColor: Colors.blueAccent,
                secondary: Icon(
                  _publicProfile
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                  color: Colors.blueAccent,
                ),
                title: Text(
                  _publicProfile ? 'Perfil público' : 'Perfil privado',
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  _publicProfile
                      ? 'Otros atletas podrán ver tus estadísticas y seguirte directamente.'
                      : 'Solo tus seguidores aceptados podrán ver tu actividad.',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                onChanged: _isSaving
                    ? null
                    : (val) => setState(() => _publicProfile = val),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                key: const Key('edit_profile_save_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Text(
                        'GUARDAR CAMBIOS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputAction? textInputAction,
  }) {
    final fill = AppTheme.cardBg(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    return TextField(
      key: fieldKey,
      controller: controller,
      enabled: !_isSaving,
      style: TextStyle(color: primaryText),
      textInputAction: textInputAction,
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        labelText: label,
        labelStyle: TextStyle(color: secondaryText),
        prefixIcon: Icon(icon, color: secondaryText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    final hasDate = _birthDate != null;
    final labelText =
        hasDate ? _formatDateDisplay(_birthDate!) : 'Fecha de nacimiento';
    final fill = AppTheme.cardBg(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    return InkWell(
      key: const Key('edit_profile_dob'),
      onTap: _isSaving ? null : _pickBirthDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: fill,
          labelText: hasDate ? 'Fecha de nacimiento' : null,
          labelStyle: TextStyle(color: secondaryText),
          prefixIcon: Icon(Icons.cake_outlined, color: secondaryText),
          suffixIcon: hasDate
              ? IconButton(
                  key: const Key('edit_profile_clear_dob'),
                  icon: Icon(Icons.close_rounded, color: secondaryText),
                  tooltip: 'Borrar fecha de nacimiento',
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                            _birthDate = null;
                            _clearBirthDate = true;
                          }),
                )
              : const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blueAccent,
                  size: 20,
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderColor(context)),
          ),
        ),
        child: Text(
          labelText,
          style: TextStyle(
            color: hasDate ? primaryText : secondaryText,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final secondaryText = AppTheme.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.language_rounded, color: secondaryText),
          const SizedBox(width: 12),
          Text(
            'Idioma',
            style: TextStyle(color: secondaryText, fontSize: 15),
          ),
          const Spacer(),
          _LanguagePill(
            key: const Key('edit_profile_lang_es'),
            label: 'Español',
            selected: _selectedLanguage == 'es',
            onTap: _isSaving
                ? null
                : () => setState(() => _selectedLanguage = 'es'),
          ),
          const SizedBox(width: 8),
          _LanguagePill(
            key: const Key('edit_profile_lang_en'),
            label: 'English',
            selected: _selectedLanguage == 'en',
            onTap: _isSaving
                ? null
                : () => setState(() => _selectedLanguage = 'en'),
          ),
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _LanguagePill({
    super.key,
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
          color: selected ? Colors.blueAccent : AppTheme.elevatedBg(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary(context),
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

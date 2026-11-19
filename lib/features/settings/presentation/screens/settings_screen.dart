import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/core_dependencies.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/app_permissions_service.dart';
import '../../../../core/services/workout_export_service.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weight_converter.dart';
import '../../../auth/auth_dependencies.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/use_cases/change_password.dart';
import '../../../profile/domain/use_cases/delete_account.dart';
import '../../../profile/domain/use_cases/get_current_user_profile.dart';
import '../../../profile/domain/use_cases/update_user_profile.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/profile_dependencies.dart';
import '../../../workouts/domain/use_cases/get_workout_history.dart';
import '../../../workouts/presentation/services/rest_timer_notification_service.dart';
import '../../../workouts/workout_dependencies.dart';

/// Pantalla centralizada de configuración de la aplicación.
class SettingsScreen extends StatefulWidget {
  final AppSettingsService? settingsService;
  final SessionService? sessionService;
  final GetCurrentUserProfile? getCurrentUserProfileUseCase;
  final UpdateUserProfile? updateUserProfileUseCase;
  final ChangePassword? changePasswordUseCase;
  final DeleteAccount? deleteAccountUseCase;
  final GetWorkoutHistory? getWorkoutHistoryUseCase;
  final RestTimerNotificationService? nativeService;
  final AppPermissionsService? permissionsService;
  final Future<void> Function()? onLogout;
  final VoidCallback? onAccountDeletedOrLoggedOut;

  const SettingsScreen({
    super.key,
    this.settingsService,
    this.sessionService,
    this.getCurrentUserProfileUseCase,
    this.updateUserProfileUseCase,
    this.changePasswordUseCase,
    this.deleteAccountUseCase,
    this.getWorkoutHistoryUseCase,
    this.nativeService,
    this.permissionsService,
    this.onLogout,
    this.onAccountDeletedOrLoggedOut,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _restPresets = [30, 60, 90, 120, 150, 180];

  late final AppSettingsService _settingsService;
  late final SessionService _sessionService;
  late final GetCurrentUserProfile _getCurrentUserProfile;
  late final UpdateUserProfile _updateUserProfile;
  late final ChangePassword _changePassword;
  late final DeleteAccount _deleteAccount;
  late final GetWorkoutHistory _getWorkoutHistory;
  late final RestTimerNotificationService _nativeService;
  late final AppPermissionsService _permissionsService;

  UserProfile? _profile;
  bool _loadingProfile = true;
  bool _savingProfileField = false;
  bool _exportingHistory = false;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? CoreDependencies.settingsService;
    _sessionService = widget.sessionService ?? CoreDependencies.sessionService;
    _getCurrentUserProfile =
        widget.getCurrentUserProfileUseCase ??
        ProfileDependencies.getCurrentUserProfileUseCase;
    _updateUserProfile =
        widget.updateUserProfileUseCase ??
        ProfileDependencies.updateUserProfileUseCase;
    _changePassword =
        widget.changePasswordUseCase ??
        ProfileDependencies.changePasswordUseCase;
    _deleteAccount =
        widget.deleteAccountUseCase ?? ProfileDependencies.deleteAccountUseCase;
    _getWorkoutHistory =
        widget.getWorkoutHistoryUseCase ??
        WorkoutDependencies.getWorkoutHistoryUseCase;
    _nativeService = widget.nativeService ?? RestTimerNotificationService();
    _permissionsService =
        widget.permissionsService ?? CoreDependencies.permissionsService;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final profile = await _getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _updatePrivacyField(UserProfile updated) async {
    final previous = _profile;
    if (previous == null || _savingProfileField) return;

    setState(() {
      _profile = updated;
      _savingProfileField = true;
    });

    try {
      final saved = await _updateUserProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _savingProfileField = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profile = previous;
        _savingProfileField = false;
      });
      _showSnack(_extractErrorMessage(e), color: Colors.redAccent);
    }
  }

  Future<void> _changeLanguage(String code) async {
    await _settingsService.setLanguageCode(code);
    final profile = _profile;
    if (profile == null) return;
    try {
      final saved = await _updateUserProfile(
        profile.copyWith(languagePreference: code),
      );
      if (mounted) setState(() => _profile = saved);
    } catch (_) {
      // Mantiene la preferencia local en AppSettings aunque falle el sync remoto.
    }
  }

  Future<void> _openPersonalDataEditor() async {
    final profile = _profile;
    if (profile == null) return;

    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
          updateUserProfileUseCase: _updateUserProfile,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _profile = updated);
      final lang = (updated.languagePreference ?? '').toLowerCase();
      if (lang == 'es' || lang == 'en') {
        await _settingsService.setLanguageCode(lang);
      }
      if (!mounted) return;
      _showSnack(
        AppStrings.fromCode(_settingsService.settings.languageCode).isEn
            ? 'Profile updated'
            : 'Perfil actualizado correctamente',
        color: Colors.green,
      );
    }
  }

  Future<int?> _resolveUserId() async {
    final profileId = _profile?.userId;
    if (profileId != null && profileId > 0) return profileId;
    return await _sessionService.getUserId();
  }

  Future<void> _showChangePasswordDialog() async {
    final strings = AppStrings.fromCode(_settingsService.settings.languageCode);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        strings: strings,
        onSubmit: (cur, next) async {
          final userId = await _resolveUserId();
          if (userId == null || userId <= 0) {
            throw const AuthenticationFailure(
              'No se pudo identificar tu sesión',
            );
          }
          await _changePassword(
            userId: userId,
            currentPassword: cur,
            newPassword: next,
          );
        },
        extractErrorMessage: _extractErrorMessage,
      ),
    );

    if (changed == true && mounted) {
      _showSnack(
        strings.isEn
            ? 'Password updated successfully'
            : 'Contraseña actualizada correctamente',
        color: Colors.green,
      );
    }
  }

  Future<void> _openExportSheet() async {
    final strings = AppStrings.fromCode(_settingsService.settings.languageCode);
    final unit = _settingsService.settings.weightUnit;
    setState(() => _exportingHistory = true);

    try {
      final userId = await _resolveUserId();
      if (userId == null || userId <= 0) {
        throw const AuthenticationFailure('No se pudo identificar tu sesión');
      }
      final workouts = await _getWorkoutHistory(userId);
      if (!mounted) return;
      setState(() => _exportingHistory = false);

      String format = 'csv';
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.cardBg(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) {
            final exportedContent = format == 'csv'
                ? WorkoutExportService.toCsv(workouts, unit: unit)
                : WorkoutExportService.toJson(workouts, unit: unit);
            final fileExt = format.toUpperCase();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.exportHistoryTitle,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${workouts.length} sesiones',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            key: const Key('settings_export_csv'),
                            label: const Center(child: Text('CSV')),
                            selected: format == 'csv',
                            onSelected: (_) =>
                                setSheetState(() => format = 'csv'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            key: const Key('settings_export_json'),
                            label: const Center(child: Text('JSON')),
                            selected: format == 'json',
                            onSelected: (_) =>
                                setSheetState(() => format = 'json'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 190),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.elevatedBg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.borderColor(context),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          exportedContent,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('settings_export_copy_button'),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: exportedContent),
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                _showSnack(
                                  strings.isEn
                                      ? '$fileExt copied to clipboard'
                                      : '$fileExt copiado al portapapeles',
                                  color: Colors.green,
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(strings.isEn ? 'Copy' : 'Copiar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const Key('settings_export_share_button'),
                            onPressed: () async {
                              final shared = await _nativeService.shareText(
                                text: exportedContent,
                                subject: 'Progressive $fileExt Export',
                                mimeType: format == 'csv'
                                    ? 'text/csv'
                                    : 'application/json',
                              );
                              if (!shared) {
                                await Clipboard.setData(
                                  ClipboardData(text: exportedContent),
                                );
                              }
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                _showSnack(
                                  shared
                                      ? (strings.isEn
                                          ? 'Opening share sheet...'
                                          : 'Abriendo menú para compartir...')
                                      : (strings.isEn
                                          ? '$fileExt copied to clipboard'
                                          : '$fileExt copiado al portapapeles'),
                                  color: Colors.green,
                                );
                              }
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(strings.isEn ? 'Share' : 'Compartir'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exportingHistory = false);
      _showSnack(_extractErrorMessage(e), color: Colors.redAccent);
    }
  }

  Future<void> _performSessionLogout() async {
    try {
      if (widget.onLogout != null) {
        await widget.onLogout!();
      } else {
        await AuthDependencies.repository.logout();
      }
    } catch (_) {
    } finally {
      _permissionsService.resetSession();
      if (mounted) {
        if (widget.onAccountDeletedOrLoggedOut != null) {
          widget.onAccountDeletedOrLoggedOut!();
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LoginScreen(loginUseCase: AuthDependencies.loginUseCase),
            ),
            (_) => false,
          );
        }
      }
    }
  }

  Future<void> _confirmLogout() async {
    final strings = AppStrings.fromCode(_settingsService.settings.languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          strings.logoutTitle,
          style: TextStyle(
            color: AppTheme.textPrimary(dialogContext),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          strings.logoutMessage,
          style: TextStyle(color: AppTheme.textSecondary(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              strings.logOut,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performSessionLogout();
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final strings = AppStrings.fromCode(_settingsService.settings.languageCode);
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(
        strings: strings,
        onSubmit: (password) async {
          final userId = await _resolveUserId();
          if (userId == null || userId <= 0) {
            throw const AuthenticationFailure(
              'No se pudo identificar tu sesión',
            );
          }
          await _deleteAccount(
            userId: userId,
            password: password,
          );
        },
        extractErrorMessage: _extractErrorMessage,
      ),
    );

    if (deleted == true) {
      await _performSessionLogout();
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is Failure) return error.message;
    return error
        .toString()
        .replaceFirst(
          RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'),
          '',
        )
        .trim();
  }

  void _showSnack(String message, {required Color color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _formatRestChip(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final min = seconds ~/ 60;
    final rem = seconds % 60;
    return rem == 0 ? '${min}m' : '${min}m ${rem}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, _) {
        final settings = _settingsService.settings;
        final strings = AppStrings.fromCode(settings.languageCode);

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg(context),
          appBar: AppBar(
            backgroundColor: AppTheme.scaffoldBg(context),
            foregroundColor: AppTheme.textPrimary(context),
            elevation: 0,
            title: Text(
              strings.settingsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _SectionTitle(strings.sectionAppearance),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.palette_outlined,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            strings.themeLabel,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentPill(
                              key: const Key('settings_theme_light'),
                              label: strings.themeLight,
                              icon: Icons.light_mode_rounded,
                              selected: settings.themeMode == ThemeMode.light,
                              onTap: () => _settingsService.setThemeMode(
                                ThemeMode.light,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SegmentPill(
                              key: const Key('settings_theme_dark'),
                              label: strings.themeDark,
                              icon: Icons.dark_mode_rounded,
                              selected: settings.themeMode == ThemeMode.dark,
                              onTap: () => _settingsService.setThemeMode(
                                ThemeMode.dark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SegmentPill(
                              key: const Key('settings_theme_system'),
                              label: strings.themeSystem,
                              icon: Icons.brightness_auto_rounded,
                              selected: settings.themeMode == ThemeMode.system,
                              onTap: () => _settingsService.setThemeMode(
                                ThemeMode.system,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SectionTitle(strings.sectionPrivacy),
              _SettingsCard(
                child: _buildPrivacySection(context, strings),
              ),
              const SizedBox(height: 20),

              _SectionTitle(strings.sectionLanguageUnits),
              _SettingsCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.languageLabel,
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _SegmentPill(
                            key: const Key('settings_lang_es'),
                            label: 'Español',
                            selected: settings.languageCode == 'es',
                            onTap: () => _changeLanguage('es'),
                          ),
                          const SizedBox(width: 8),
                          _SegmentPill(
                            key: const Key('settings_lang_en'),
                            label: 'English',
                            selected: settings.languageCode == 'en',
                            onTap: () => _changeLanguage('en'),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monitor_weight_outlined,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.weightUnitLabel,
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _SegmentPill(
                            key: const Key('settings_unit_kg'),
                            label: 'kg',
                            selected: settings.weightUnit == WeightUnit.kg,
                            onTap: () =>
                                _settingsService.setWeightUnit(WeightUnit.kg),
                          ),
                          const SizedBox(width: 8),
                          _SegmentPill(
                            key: const Key('settings_unit_lb'),
                            label: 'lb',
                            selected: settings.weightUnit == WeightUnit.lb,
                            onTap: () =>
                                _settingsService.setWeightUnit(WeightUnit.lb),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SectionTitle(strings.sectionTrainingTimer),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                strings.defaultRestTitle,
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.defaultRestSubtitle,
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _restPresets.map((sec) {
                              final selected =
                                  settings.defaultRestSeconds == sec;
                              return _SegmentPill(
                                key: Key('settings_rest_$sec'),
                                label: _formatRestChip(sec),
                                selected: selected,
                                onTap: () =>
                                    _settingsService.setDefaultRestSeconds(sec),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    SwitchListTile(
                      key: const Key('settings_rest_sound_switch'),
                      value: settings.restSoundEnabled,
                      activeThumbColor: Colors.blueAccent,
                      secondary: const Icon(
                        Icons.volume_up_outlined,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.restSoundTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        strings.restSoundSubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: _settingsService.setRestSoundEnabled,
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    SwitchListTile(
                      key: const Key('settings_rest_vibration_switch'),
                      value: settings.restVibrationEnabled,
                      activeThumbColor: Colors.blueAccent,
                      secondary: const Icon(
                        Icons.vibration_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.restVibrationTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        strings.restVibrationSubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: _settingsService.setRestVibrationEnabled,
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    SwitchListTile(
                      key: const Key('settings_rest_notification_switch'),
                      value: settings.restNotificationEnabled,
                      activeThumbColor: Colors.blueAccent,
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.restNotificationTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        strings.restNotificationSubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: _settingsService.setRestNotificationEnabled,
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    SwitchListTile(
                      key: const Key('settings_keep_screen_on_switch'),
                      value: settings.keepScreenOn,
                      activeThumbColor: Colors.blueAccent,
                      secondary: const Icon(
                        Icons.screen_lock_portrait_outlined,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.keepScreenOnTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        strings.keepScreenOnSubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: _settingsService.setKeepScreenOn,
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    SwitchListTile(
                      key: const Key('settings_haptic_set_switch'),
                      value: settings.hapticOnSetComplete,
                      activeThumbColor: Colors.blueAccent,
                      secondary: const Icon(
                        Icons.touch_app_outlined,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.hapticSetTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        strings.hapticSetSubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: _settingsService.setHapticOnSetComplete,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SectionTitle(strings.sectionAccountSecurity),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('settings_change_password'),
                      leading: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.changePasswordTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        strings.changePasswordSubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary(context),
                      ),
                      onTap: _showChangePasswordDialog,
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    ListTile(
                      key: const Key('settings_export_history'),
                      leading: const Icon(
                        Icons.download_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        strings.exportHistoryTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        strings.exportHistorySubtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      trailing: _exportingHistory
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary(context),
                            ),
                      onTap: _exportingHistory ? null : _openExportSheet,
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    ListTile(
                      key: const Key('settings_logout_button'),
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: Colors.orangeAccent,
                      ),
                      title: Text(
                        strings.logOut,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary(context),
                      ),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _SectionTitle(strings.dangerZoneTitle, color: Colors.redAccent),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: ListTile(
                  key: const Key('settings_delete_account_button'),
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    strings.deleteAccountTitle,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    strings.deleteAccountSubtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.redAccent,
                  ),
                  onTap: _showDeleteAccountDialog,
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacySection(BuildContext context, AppStrings strings) {
    if (_loadingProfile) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.offlinePrivacyHint,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadProfile,
              child: Text(strings.retry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SwitchListTile(
          key: const Key('settings_public_profile_switch'),
          value: profile.publicProfile,
          activeThumbColor: Colors.blueAccent,
          secondary: Icon(
            profile.publicProfile
                ? Icons.public_rounded
                : Icons.lock_outline_rounded,
            color: Colors.blueAccent,
          ),
          title: Text(
            strings.publicAccountTitle,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            strings.publicAccountSubtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          onChanged: _savingProfileField
              ? null
              : (val) => _updatePrivacyField(
                  profile.copyWith(publicProfile: val),
                ),
        ),
        Divider(height: 1, color: AppTheme.borderColor(context)),
        SwitchListTile(
          key: const Key('settings_show_dob_switch'),
          value: profile.showDateOfBirth,
          activeThumbColor: Colors.blueAccent,
          secondary: const Icon(
            Icons.cake_outlined,
            color: Colors.blueAccent,
          ),
          title: Text(
            strings.showDobTitle,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            strings.showDobSubtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          onChanged: _savingProfileField
              ? null
              : (val) => _updatePrivacyField(
                  profile.copyWith(showDateOfBirth: val),
                ),
        ),
        Divider(height: 1, color: AppTheme.borderColor(context)),
        SwitchListTile(
          key: const Key('settings_show_stats_switch'),
          value: profile.showGlobalStats,
          activeThumbColor: Colors.blueAccent,
          secondary: const Icon(
            Icons.bar_chart_rounded,
            color: Colors.blueAccent,
          ),
          title: Text(
            strings.showStatsTitle,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            strings.showStatsSubtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          onChanged: _savingProfileField
              ? null
              : (val) => _updatePrivacyField(
                  profile.copyWith(showGlobalStats: val),
                ),
        ),
        Divider(height: 1, color: AppTheme.borderColor(context)),
        SwitchListTile(
          key: const Key('settings_show_routines_switch'),
          value: profile.showPublicRoutines,
          activeThumbColor: Colors.blueAccent,
          secondary: const Icon(
            Icons.list_alt_rounded,
            color: Colors.blueAccent,
          ),
          title: Text(
            strings.showRoutinesTitle,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            strings.showRoutinesSubtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          onChanged: _savingProfileField
              ? null
              : (val) => _updatePrivacyField(
                  profile.copyWith(showPublicRoutines: val),
                ),
        ),
        Divider(height: 1, color: AppTheme.borderColor(context)),
        ListTile(
          key: const Key('settings_edit_personal_data'),
          leading: const Icon(
            Icons.badge_outlined,
            color: Colors.blueAccent,
          ),
          title: Text(
            strings.editPersonalData,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            strings.editPersonalDataSubtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary(context),
          ),
          onTap: _openPersonalDataEditor,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;

  const _SectionTitle(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color ?? AppTheme.textSecondary(context),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: child,
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentPill({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueAccent
              : AppTheme.elevatedBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Colors.blueAccent
                : AppTheme.borderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary(context),
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AppStrings strings;
  final Future<void> Function(String currentPassword, String newPassword)
      onSubmit;
  final String Function(Object error) extractErrorMessage;

  const _ChangePasswordDialog({
    required this.strings,
    required this.onSubmit,
    required this.extractErrorMessage,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorText;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = widget.strings;
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty) {
      setState(() {
        _errorText = s.isEn
            ? 'Enter your current password'
            : 'Introduce tu contraseña actual';
      });
      return;
    }
    if (next.length < 6) {
      setState(() {
        _errorText = s.isEn
            ? 'Password must have at least 6 characters'
            : 'La nueva contraseña debe tener al menos 6 caracteres';
      });
      return;
    }
    if (next != confirm) {
      setState(() {
        _errorText = s.isEn
            ? 'Passwords do not match'
            : 'Las contraseñas nuevas no coinciden';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(current, next);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = widget.extractErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      title: Text(
        s.changePasswordTitle,
        style: TextStyle(
          color: AppTheme.textPrimary(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('settings_current_password_field'),
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              enabled: !_saving,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                labelText: s.isEn ? 'Current password' : 'Contraseña actual',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings_new_password_field'),
              controller: _newCtrl,
              obscureText: _obscureNew,
              enabled: !_saving,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                labelText: s.isEn ? 'New password' : 'Nueva contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings_confirm_password_field'),
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              enabled: !_saving,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                labelText:
                    s.isEn ? 'Confirm new password' : 'Confirmar contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          key: const Key('settings_confirm_change_password'),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(s.isEn ? 'Update' : 'Actualizar'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final AppStrings strings;
  final Future<void> Function(String password) onSubmit;
  final String Function(Object error) extractErrorMessage;

  const _DeleteAccountDialog({
    required this.strings,
    required this.onSubmit,
    required this.extractErrorMessage,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _wordCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _deleting = false;
  bool _obscurePass = true;
  String? _errorText;

  @override
  void dispose() {
    _wordCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = widget.strings;
    final password = _passCtrl.text;

    if (password.isEmpty) {
      setState(() {
        _errorText = s.isEn
            ? 'Enter your password'
            : 'Introduce tu contraseña actual';
      });
      return;
    }

    setState(() {
      _deleting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(password);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _errorText = widget.extractErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final expectedWord = s.deleteConfirmKeyword;
    final wordMatches = _wordCtrl.text.trim().toUpperCase() == expectedWord;

    return AlertDialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      title: Text(
        s.deleteAccountTitle,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.isEn
                  ? 'This action is permanent and will remove your routines, workouts, and profile. Type $expectedWord and enter your password to confirm.'
                  : 'Esta acción es permanente y eliminará tus rutinas, entrenamientos y perfil. Escribe $expectedWord e introduce tu contraseña para confirmar.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('settings_delete_confirm_word'),
              controller: _wordCtrl,
              enabled: !_deleting,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.isEn
                    ? 'Type $expectedWord'
                    : 'Escribe $expectedWord',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings_delete_password_field'),
              controller: _passCtrl,
              obscureText: _obscurePass,
              enabled: !_deleting,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                labelText: s.isEn ? 'Current password' : 'Contraseña actual',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          key: const Key('settings_confirm_delete_account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: (_deleting || !wordMatches) ? null : _submit,
          child: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(s.isEn ? 'Delete account' : 'Eliminar cuenta'),
        ),
      ],
    );
  }
}

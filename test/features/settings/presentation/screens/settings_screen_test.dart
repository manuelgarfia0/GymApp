import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/core/session/session_service.dart';
import 'package:gym_app/core/settings/app_settings_service.dart';
import 'package:gym_app/core/storage/secure_storage_service.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/utils/weight_converter.dart';
import 'package:gym_app/features/profile/domain/entities/user_profile.dart';
import 'package:gym_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_app/features/profile/domain/use_cases/change_password.dart';
import 'package:gym_app/features/profile/domain/use_cases/delete_account.dart';
import 'package:gym_app/features/profile/domain/use_cases/get_current_user_profile.dart';
import 'package:gym_app/features/profile/domain/use_cases/update_user_profile.dart';
import 'package:gym_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:gym_app/features/workouts/domain/entities/workout.dart';
import 'package:gym_app/features/workouts/domain/repositories/workout_repository.dart';
import 'package:gym_app/features/workouts/domain/use_cases/get_workout_history.dart';

class _FakeProfileRepo implements ProfileRepository {
  UserProfile profile;
  int updateCalls = 0;
  String? lastChangedCurrent;
  String? lastChangedNew;
  String? lastDeletedPassword;

  _FakeProfileRepo(this.profile);

  @override
  Future<UserProfile?> getCurrentUserProfile() async => profile;

  @override
  Future<UserProfile?> getUserProfile(int userId) async => profile;

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    updateCalls++;
    profile = userProfile;
    return userProfile;
  }

  @override
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    lastChangedCurrent = currentPassword;
    lastChangedNew = newPassword;
  }

  @override
  Future<void> deleteAccount(int userId, String password) async {
    lastDeletedPassword = password;
  }
}

class _FakeWorkoutRepo extends Fake implements WorkoutRepository {
  @override
  Future<List<Workout>> getUserWorkouts(int userId) async => [];
}

class _StubStorageService extends Fake implements SecureStorageService {}

class _StubSessionService extends SessionService {
  final int uid;
  _StubSessionService(this.uid) : super(_StubStorageService());

  @override
  Future<int?> getUserId() async => uid;
}

void main() {
  UserProfile sampleProfile() => const UserProfile(
        userId: 7,
        username: 'manuel',
        email: 'manuel@test.com',
        isPremium: false,
        publicProfile: true,
        showDateOfBirth: true,
        showGlobalStats: true,
        showPublicRoutines: true,
        languagePreference: 'es',
      );

  Future<void> pumpSettings(
    WidgetTester tester, {
    required AppSettingsService settingsService,
    required _FakeProfileRepo repo,
    VoidCallback? onClosedSession,
  }) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: settingsService,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsService.settings.themeMode,
          home: SettingsScreen(
            settingsService: settingsService,
            sessionService: _StubSessionService(7),
            getCurrentUserProfileUseCase: GetCurrentUserProfile(repo),
            updateUserProfileUseCase: UpdateUserProfile(repo),
            changePasswordUseCase: ChangePassword(repo),
            deleteAccountUseCase: DeleteAccount(repo),
            getWorkoutHistoryUseCase: GetWorkoutHistory(_FakeWorkoutRepo()),
            onLogout: () async {},
            onAccountDeletedOrLoggedOut: onClosedSession,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('switches ThemeMode live between Light, Dark, and System', (
      tester,
    ) async {
      final settings = AppSettingsService();
      final repo = _FakeProfileRepo(sampleProfile());

      await pumpSettings(tester, settingsService: settings, repo: repo);

      await tester.tap(find.byKey(const Key('settings_theme_light')));
      await tester.pumpAndSettle();
      expect(settings.settings.themeMode, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light,
      );

      await tester.tap(find.byKey(const Key('settings_theme_system')));
      await tester.pumpAndSettle();
      expect(settings.settings.themeMode, ThemeMode.system);

      await tester.tap(find.byKey(const Key('settings_theme_dark')));
      await tester.pumpAndSettle();
      expect(settings.settings.themeMode, ThemeMode.dark);
    });

    testWidgets(
      'toggles granular privacy switches and syncs via UpdateUserProfile',
      (tester) async {
        final settings = AppSettingsService();
        final repo = _FakeProfileRepo(sampleProfile());

        await pumpSettings(tester, settingsService: settings, repo: repo);

        for (final keyStr in [
          'settings_public_profile_switch',
          'settings_show_dob_switch',
          'settings_show_stats_switch',
          'settings_show_routines_switch',
        ]) {
          final target = find.byKey(Key(keyStr));
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        expect(repo.updateCalls, 4);
        expect(repo.profile.publicProfile, isFalse);
        expect(repo.profile.showDateOfBirth, isFalse);
        expect(repo.profile.showGlobalStats, isFalse);
        expect(repo.profile.showPublicRoutines, isFalse);
      },
    );

    testWidgets('updates language, weight units, and training timer toggles', (
      tester,
    ) async {
      final settings = AppSettingsService();
      final repo = _FakeProfileRepo(sampleProfile());

      await pumpSettings(tester, settingsService: settings, repo: repo);

      final langEn = find.byKey(const Key('settings_lang_en'));
      await tester.ensureVisible(langEn);
      await tester.tap(langEn);
      await tester.pumpAndSettle();
      expect(settings.settings.languageCode, 'en');
      expect(repo.profile.languagePreference, 'en');

      final unitLb = find.byKey(const Key('settings_unit_lb'));
      await tester.ensureVisible(unitLb);
      await tester.tap(unitLb);
      await tester.pumpAndSettle();
      expect(settings.settings.weightUnit, WeightUnit.lb);

      final rest120 = find.byKey(const Key('settings_rest_120'));
      await tester.ensureVisible(rest120);
      await tester.tap(rest120);
      await tester.pumpAndSettle();
      expect(settings.settings.defaultRestSeconds, 120);

      for (final keyStr in [
        'settings_rest_sound_switch',
        'settings_rest_vibration_switch',
        'settings_rest_notification_switch',
        'settings_keep_screen_on_switch',
        'settings_haptic_set_switch',
      ]) {
        final tile = find.byKey(Key(keyStr));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }

      expect(settings.settings.restSoundEnabled, isFalse);
      expect(settings.settings.restVibrationEnabled, isFalse);
      expect(settings.settings.restNotificationEnabled, isFalse);
      expect(settings.settings.keepScreenOn, isTrue);
      expect(settings.settings.hapticOnSetComplete, isFalse);
    });

    testWidgets('validates and submits Change Password dialog', (tester) async {
      final settings = AppSettingsService();
      final repo = _FakeProfileRepo(sampleProfile());

      await pumpSettings(tester, settingsService: settings, repo: repo);

      final item = find.byKey(const Key('settings_change_password'));
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings_current_password_field')),
        'oldpass',
      );
      await tester.enterText(
        find.byKey(const Key('settings_new_password_field')),
        'newpass123',
      );
      await tester.enterText(
        find.byKey(const Key('settings_confirm_password_field')),
        'mismatch',
      );
      await tester.tap(
        find.byKey(const Key('settings_confirm_change_password')),
      );
      await tester.pump();
      expect(find.text('Las contraseñas nuevas no coinciden'), findsOneWidget);
      expect(repo.lastChangedNew, isNull);

      await tester.enterText(
        find.byKey(const Key('settings_confirm_password_field')),
        'newpass123',
      );
      await tester.tap(
        find.byKey(const Key('settings_confirm_change_password')),
      );
      await tester.pumpAndSettle();

      expect(repo.lastChangedCurrent, 'oldpass');
      expect(repo.lastChangedNew, 'newpass123');
    });

    testWidgets('requires confirmation keyword and password to delete account', (
      tester,
    ) async {
      final settings = AppSettingsService();
      final repo = _FakeProfileRepo(sampleProfile());
      var sessionClosed = false;

      await pumpSettings(
        tester,
        settingsService: settings,
        repo: repo,
        onClosedSession: () => sessionClosed = true,
      );

      final deleteTile = find.byKey(
        const Key('settings_delete_account_button'),
      );
      await tester.ensureVisible(deleteTile);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      final confirmBtnFinder = find.byKey(
        const Key('settings_confirm_delete_account'),
      );
      expect(
        tester.widget<ElevatedButton>(confirmBtnFinder).onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('settings_delete_confirm_word')),
        'ELIMINAR',
      );
      await tester.enterText(
        find.byKey(const Key('settings_delete_password_field')),
        'secret123',
      );
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(confirmBtnFinder).onPressed,
        isNotNull,
      );

      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      expect(repo.lastDeletedPassword, 'secret123');
      expect(sessionClosed, isTrue);
    });
  });
}

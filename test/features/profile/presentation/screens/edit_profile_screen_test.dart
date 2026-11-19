import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/features/profile/domain/entities/user_profile.dart';
import 'package:gym_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_app/features/profile/domain/use_cases/update_user_profile.dart';
import 'package:gym_app/features/profile/presentation/screens/edit_profile_screen.dart';

class _FakeProfileRepository implements ProfileRepository {
  UserProfile? lastUpdatedProfile;
  Object? errorToThrow;
  int updateCallCount = 0;

  @override
  Future<UserProfile?> getCurrentUserProfile() async => lastUpdatedProfile;

  @override
  Future<UserProfile?> getUserProfile(int userId) async => lastUpdatedProfile;

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    updateCallCount++;
    lastUpdatedProfile = userProfile;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return userProfile;
  }

  @override
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {}

  @override
  Future<void> deleteAccount(int userId, String password) async {}
}

void main() {
  UserProfile buildSampleProfile() {
    return UserProfile(
      userId: 10,
      username: 'manuel',
      email: 'manuel@example.com',
      isPremium: false,
      publicProfile: true,
      languagePreference: 'es',
      firstName: 'Manuel',
      lastName: 'Garcia',
      dateOfBirth: DateTime(1998, 5, 10),
    );
  }

  Future<void> pumpHost(
    WidgetTester tester, {
    required UserProfile profile,
    required UpdateUserProfile useCase,
    required void Function(UserProfile? result) onPopped,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final res = await Navigator.of(context).push<UserProfile>(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      profile: profile,
                      updateUserProfileUseCase: useCase,
                    ),
                  ),
                );
                onPopped(res);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('EditProfileScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows validation message when firstName is empty', (
      tester,
    ) async {
      final repo = _FakeProfileRepository();
      final useCase = UpdateUserProfile(repo);

      await pumpHost(
        tester,
        profile: buildSampleProfile(),
        useCase: useCase,
        onPopped: (_) {},
      );

      await tester.enterText(
        find.byKey(const Key('edit_profile_first_name')),
        '   ',
      );
      final saveButton = find.byKey(const Key('edit_profile_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Introduce tu nombre'), findsOneWidget);
      expect(repo.updateCallCount, 0);
    });

    testWidgets(
      'saves edited fields, clears DOB, updates language/privacy and pops updated profile',
      (tester) async {
        final repo = _FakeProfileRepository();
        final useCase = UpdateUserProfile(repo);
        UserProfile? poppedResult;

        await pumpHost(
          tester,
          profile: buildSampleProfile(),
          useCase: useCase,
          onPopped: (res) => poppedResult = res,
        );

        await tester.enterText(
          find.byKey(const Key('edit_profile_first_name')),
          'Carlos',
        );
        await tester.enterText(
          find.byKey(const Key('edit_profile_last_name')),
          'Lopez',
        );

        final clearDob = find.byKey(const Key('edit_profile_clear_dob'));
        await tester.ensureVisible(clearDob);
        await tester.tap(clearDob);
        await tester.pump();

        final enLang = find.byKey(const Key('edit_profile_lang_en'));
        await tester.ensureVisible(enLang);
        await tester.tap(enLang);
        await tester.pump();

        final publicSwitch = find.byKey(
          const Key('edit_profile_public_switch'),
        );
        await tester.ensureVisible(publicSwitch);
        await tester.tap(publicSwitch);
        await tester.pump();

        final saveButton = find.byKey(const Key('edit_profile_save_button'));
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(repo.updateCallCount, 1);
        expect(repo.lastUpdatedProfile?.firstName, 'Carlos');
        expect(repo.lastUpdatedProfile?.lastName, 'Lopez');
        expect(repo.lastUpdatedProfile?.dateOfBirth, isNull);
        expect(repo.lastUpdatedProfile?.languagePreference, 'en');
        expect(repo.lastUpdatedProfile?.publicProfile, isFalse);

        expect(poppedResult, isNotNull);
        expect(poppedResult?.firstName, 'Carlos');
        expect(poppedResult?.lastName, 'Lopez');
        expect(poppedResult?.dateOfBirth, isNull);
        expect(poppedResult?.languagePreference, 'en');
        expect(poppedResult?.publicProfile, isFalse);
      },
    );

    testWidgets('shows snackbar and stays on screen when update fails', (
      tester,
    ) async {
      final repo = _FakeProfileRepository()
        ..errorToThrow = Exception('Server rejected profile update');
      final useCase = UpdateUserProfile(repo);
      UserProfile? poppedResult;

      await pumpHost(
        tester,
        profile: buildSampleProfile(),
        useCase: useCase,
        onPopped: (res) => poppedResult = res,
      );

      final saveButton = find.byKey(const Key('edit_profile_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Server rejected profile update'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(poppedResult, isNull);
    });
  });
}

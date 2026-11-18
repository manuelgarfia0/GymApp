import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/domain/entities/user.dart';
import 'package:gym_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_app/features/auth/domain/use_cases/register_user.dart';
import 'package:gym_app/features/auth/presentation/screens/register_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<String> login(String username, String password) async => 'token';

  @override
  Future<void> logout() async {}

  @override
  Future<String> register(
    String username,
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? languagePreference,
  }) async =>
      'token';
}

void main() {
  group('RegisterScreen birth date picker locale', () {
    testWidgets('opens date picker in es_ES with Monday first and Sunday last', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es', 'ES'),
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'GB'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RegisterScreen(
            registerUseCase: RegisterUser(_FakeAuthRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final birthDateFinder = find.text('Fecha de nacimiento');
      await tester.ensureVisible(birthDateFinder);
      await tester.tap(birthDateFinder);
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(DatePickerDialog);
      expect(dialogFinder, findsOneWidget);

      final dialogContext = tester.element(dialogFinder);
      final loc = MaterialLocalizations.of(dialogContext);
      // 0 = Sunday, 1 = Monday
      expect(loc.firstDayOfWeekIndex, 1);

      // Verify Spanish weekday headers L -> X -> J -> V -> S -> D appear left to right
      final mondayX = tester.getTopLeft(find.descendant(of: dialogFinder, matching: find.text('L'))).dx;
      final wednesdayX = tester.getTopLeft(find.descendant(of: dialogFinder, matching: find.text('X'))).dx;
      final sundayX = tester.getTopLeft(find.descendant(of: dialogFinder, matching: find.text('D'))).dx;
      expect(mondayX, lessThan(wednesdayX));
      expect(wednesdayX, lessThan(sundayX));
    });
  });
}

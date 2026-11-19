import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/slow_loading_indicator.dart';

void main() {
  group('SlowLoadingIndicator', () {
    testWidgets('hides cold-start hint initially, reveals after delay, and cancels timer on dispose', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlowLoadingIndicator(
              delay: Duration(seconds: 4),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Despertando el servidor…'), findsNothing);

      // Before delay completes, hint remains hidden
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Despertando el servidor…'), findsNothing);

      // Once delay elapses, cold-start explanation appears
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Despertando el servidor…'), findsOneWidget);
      expect(
        find.text(
          'Puede tardar hasta 1 minuto tras un periodo de inactividad',
        ),
        findsOneWidget,
      );

      // Unmount earlier than delay in a second instance to confirm timer cancellation
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlowLoadingIndicator(delay: Duration(seconds: 10)),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pump();
    });
  });
}

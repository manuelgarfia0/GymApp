import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/app.dart';

void main() {
  testWidgets('App loads and shows auth check screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GymApp());

    // Verify that the app loads with the fitness center icon (auth check screen)
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

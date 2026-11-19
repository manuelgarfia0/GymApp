import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/app.dart';

void main() {
  group('GymApp keyboard dismiss actions on Android touch', () {
    testWidgets(
      'keeps focus inside field/suffix or another field, and unfocuses when tapping button or empty area',
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
      }),
      (tester) async {
        final focusNode1 = FocusNode();
        final focusNode2 = FocusNode();
        addTearDown(focusNode1.dispose);
        addTearDown(focusNode2.dispose);

        var suffixTaps = 0;
        var buttonTaps = 0;

        await tester.pumpWidget(
          MaterialApp(
            actions: GymApp.appActions,
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('field_1'),
                    focusNode: focusNode1,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        key: const Key('suffix_1'),
                        icon: const Icon(Icons.visibility),
                        onPressed: () => suffixTaps++,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('field_2'),
                    focusNode: focusNode2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('action_button'),
                    onPressed: () => buttonTaps++,
                    child: const Text('Submit'),
                  ),
                  const Expanded(
                    child: ColoredBox(
                      key: Key('empty_area'),
                      color: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Focus first field
        await tester.tap(find.byKey(const Key('field_1')));
        await tester.pumpAndSettle();
        expect(focusNode1.hasFocus, isTrue);

        // 2. Tapping suffixIcon inside the same field executes callback without closing keyboard
        await tester.tap(find.byKey(const Key('suffix_1')));
        await tester.pumpAndSettle();
        expect(suffixTaps, 1);
        expect(focusNode1.hasFocus, isTrue);

        // 3. Tapping second field transfers focus cleanly
        await tester.tap(find.byKey(const Key('field_2')));
        await tester.pumpAndSettle();
        expect(focusNode2.hasFocus, isTrue);

        // 4. Tapping an external button triggers onPressed AND unfocuses field
        await tester.tap(find.byKey(const Key('action_button')));
        await tester.pumpAndSettle();
        expect(buttonTaps, 1);
        expect(focusNode2.hasFocus, isFalse);

        // 5. Refocus first field, then tap empty space -> unfocuses cleanly
        await tester.tap(find.byKey(const Key('field_1')));
        await tester.pumpAndSettle();
        expect(focusNode1.hasFocus, isTrue);

        await tester.tap(find.byKey(const Key('empty_area')));
        await tester.pumpAndSettle();
        expect(focusNode1.hasFocus, isFalse);
      },
    );
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/services/app_permissions_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AppPermissionsService.defaultChannelName);

  group('AppPermissionsService on Android', () {
    testWidgets(
      'requests permission once per session and re-requests after resetSession or force',
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
      }),
      (tester) async {
        int calls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestPermission') {
            calls++;
            return true;
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final service = AppPermissionsService(channel: channel);

        expect(await service.requestRequiredPermissions(), isTrue);
        expect(calls, 1);

        // Second call within same session should not re-prompt
        expect(await service.requestRequiredPermissions(), isTrue);
        expect(calls, 1);

        // Reset session (e.g. logout/new login) allows requesting again
        service.resetSession();
        expect(await service.requestRequiredPermissions(), isTrue);
        expect(calls, 2);

        // force: true also bypasses session memoization
        expect(await service.requestRequiredPermissions(force: true), isTrue);
        expect(calls, 3);
      },
    );
  });
}

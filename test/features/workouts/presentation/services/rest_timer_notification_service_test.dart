import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/presentation/services/rest_timer_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(RestTimerNotificationService.channelName);

  group('RestTimerNotificationService', () {
    late List<MethodCall> recordedCalls;
    late RestTimerNotificationService service;

    setUp(() {
      recordedCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        if (call.method == 'requestPermission') return true;
        return null;
      });
      service = RestTimerNotificationService(channel: channel);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      service.setActionHandler(null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should parse all notification wire actions accurately', () {
      expect(
        RestTimerNotificationAction.fromWireValue('sub20'),
        RestTimerNotificationAction.subtract20,
      );
      expect(
        RestTimerNotificationAction.fromWireValue('add20'),
        RestTimerNotificationAction.add20,
      );
      expect(
        RestTimerNotificationAction.fromWireValue('stop'),
        RestTimerNotificationAction.stop,
      );
      expect(
        RestTimerNotificationAction.fromWireValue('completed'),
        RestTimerNotificationAction.completed,
      );
      expect(RestTimerNotificationAction.fromWireValue('unknown'), isNull);
    });

    test('should dispatch registered handler when native notification actions arrive', () async {
      final received = <RestTimerNotificationAction>[];
      service.setActionHandler(received.add);

      const codec = StandardMethodCodec();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      for (final raw in ['sub20', 'add20', 'stop', 'completed']) {
        final data = codec.encodeMethodCall(
          MethodCall('onNotificationAction', {'action': raw}),
        );
        await messenger.handlePlatformMessage(channel.name, data, (_) {});
      }

      expect(received, [
        RestTimerNotificationAction.subtract20,
        RestTimerNotificationAction.add20,
        RestTimerNotificationAction.stop,
        RestTimerNotificationAction.completed,
      ]);
    });

    test('should invoke MethodChannel commands when running on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final permissionGranted = await service.requestPermission();
        expect(permissionGranted, isTrue);

        await service.showOrUpdate(
          remainingSeconds: 60,
          totalSeconds: 90,
          isPaused: false,
          soundEnabled: true,
          vibrationEnabled: true,
          exerciseName: 'Bench Press',
        );
        await service.playCompletionFeedback(playSound: true, vibrate: true);
        await service.lightImpact();
        await service.cancel();

        expect(recordedCalls.map((c) => c.method).toList(), [
          'requestPermission',
          'showOrUpdateTimer',
          'playCompletionFeedback',
          'vibrateLight',
          'cancelTimer',
        ]);
        expect(recordedCalls[1].arguments, {
          'remainingSeconds': 60,
          'totalSeconds': 90,
          'isPaused': false,
          'soundEnabled': true,
          'vibrationEnabled': true,
          'exerciseName': 'Bench Press',
        });
        expect(recordedCalls[2].arguments, {
          'playSound': true,
          'vibrate': true,
        });
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('should degrade gracefully on non-Android platforms without throwing', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final permissionGranted = await service.requestPermission();
        expect(permissionGranted, isFalse);

        await service.showOrUpdate(
          remainingSeconds: 40,
          totalSeconds: 90,
          isPaused: false,
          soundEnabled: true,
          vibrationEnabled: true,
        );
        await service.playCompletionFeedback(playSound: true, vibrate: true);
        await service.cancel();

        expect(recordedCalls, isEmpty);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('invokes setKeepScreenOn and shareText on Android and degrades on non-Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        if (call.method == 'shareText') return true;
        return null;
      });

      await service.setKeepScreenOn(true);
      final shared = await service.shareText(
        text: 'csv-data',
        subject: 'Export',
        mimeType: 'text/csv',
      );
      expect(shared, isTrue);
      expect(recordedCalls.map((c) => c.method).toList(), [
        'setKeepScreenOn',
        'shareText',
      ]);
      expect(recordedCalls[0].arguments, {'enabled': true});
      expect(recordedCalls[1].arguments, {
        'text': 'csv-data',
        'subject': 'Export',
        'mimeType': 'text/csv',
      });

      recordedCalls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await service.setKeepScreenOn(false);
      final nonAndroidShared = await service.shareText(
        text: 'csv-data',
        subject: 'Export',
      );
      expect(nonAndroidShared, isFalse);
      expect(recordedCalls, isEmpty);
    });
  });
}

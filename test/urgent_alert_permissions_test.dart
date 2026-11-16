import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingmudde/screen/auth/urgent_alert_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const alerts = MethodChannel('com.parkingmudde.app/urgent_overlay');
  const localNotifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late bool overlayGranted;
  late bool fullScreenGranted;
  late List<String> requests;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    overlayGranted = false;
    fullScreenGranted = true;
    requests = [];

    messenger.setMockMethodCallHandler(alerts, (call) async {
      return switch (call.method) {
        'canUseFullScreenIntent' => fullScreenGranted,
        'canDrawOverlays' => overlayGranted,
        _ => throw StateError('Unexpected method: ${call.method}'),
      };
    });
    messenger.setMockMethodCallHandler(localNotifications, (call) async {
      expectSync(call.method, 'requestFullScreenIntentPermission');
      requests.add('full-screen');
      fullScreenGranted = true;
      return true;
    });
    messenger.setMockMethodCallHandler(permissions, (call) async {
      expectSync(call.method, 'requestPermissions');
      if ((call.arguments as List).contains(23)) {
        requests.add('overlay');
        return {23: overlayGranted ? 1 : 0};
      }
      expectSync(call.arguments, [17]);
      requests.add('notifications');
      return {17: 1};
    });
  });

  tearDown(() {
    for (final channel in [alerts, localNotifications, permissions]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  Future<void> startApp(WidgetTester tester) async {
    late BuildContext startupContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            startupContext = context;
            return const Scaffold(body: Text('Startup'));
          },
        ),
      ),
    );
    unawaited(requestAndroidStartupPermissions(startupContext));
    await tester.pumpAndSettle();
  }

  final dialogAllow = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, 'Allow'),
  );

  testWidgets('first Allow opens Settings only after the popup', (
    tester,
  ) async {
    fullScreenGranted = false;
    await startApp(tester);
    expect(find.text('Allow full-screen alerts?'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(dialogAllow);
    await tester.pumpAndSettle();
    expect(requests, ['full-screen']);
    expect(find.text('Allow alerts over other apps?'), findsOneWidget);

    overlayGranted = true;
    await tester.tap(dialogAllow);
    await tester.pumpAndSettle();
    expect(requests, ['full-screen', 'overlay', 'notifications']);
    expect(find.text('Startup'), findsOneWidget);
  });

  testWidgets('Deny shows one Allow button and Settings can be retried', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    expect(find.text('Urgent alerts need this permission'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Startup'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Urgent alerts need this permission'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(requests, ['overlay']);
    expect(find.text('Urgent alerts need this permission'), findsOneWidget);

    overlayGranted = true;
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(requests, ['overlay', 'overlay', 'notifications']);
    expect(find.text('Startup'), findsOneWidget);
  });

  testWidgets('granted special permissions skip the Settings flow', (
    tester,
  ) async {
    overlayGranted = true;
    await startApp(tester);
    expect(requests, ['notifications']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Startup'), findsOneWidget);
  });
}

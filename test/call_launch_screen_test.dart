import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/main.dart';
import 'package:parkingmudde/screen/calls/incoming_call_screen.dart';
import 'package:parkingmudde/screen/splash/splashpage.dart';

void main() {
  Map<String, dynamic> callData() => {
    'call_id': 'test-call',
    'call_token': 'test-token',
    'type': 'IN_APP_CALL',
    'status': 'RINGING',
    'expires_at': DateTime.now()
        .add(const Duration(seconds: 90))
        .toUtc()
        .toIso8601String(),
  };

  testWidgets(
    'cold incoming call renders without waiting for dashboard or Firebase',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({'user_id': '103'});
      await tester.pumpWidget(MyApp(launchCall: callData()));
      await tester.pump();
      await tester.pump();
      expect(find.byType(IncomingCallScreen), findsOneWidget);
      expect(find.byType(Splashpage), findsNothing);

      // Answer replaces ringing with the active call. This must not start splash.
      final context = tester.element(find.byType(IncomingCallScreen));
      Navigator.of(context).pushReplacement<void, bool>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Active test call')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active test call'), findsOneWidget);
      expect(find.byType(Splashpage), findsNothing);

      Navigator.of(tester.element(find.text('Active test call'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(Splashpage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('signed-out launch cannot open or answer a call', (tester) async {
    SharedPreferences.setMockInitialValues({'is_logging_out': true});
    await tester.pumpWidget(MyApp(launchCall: callData()));
    await tester.pump();
    await tester.pump();
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(find.byType(Splashpage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

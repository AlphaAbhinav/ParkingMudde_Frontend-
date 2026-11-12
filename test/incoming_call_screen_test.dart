import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingmudde/screen/calls/incoming_call_screen.dart';

void main() {
  testWidgets('an expired call does not remain over the app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => IncomingCallScreen(
                    callData: {
                      'call_id': 'expired-call',
                      'call_token': 'expired-token',
                      'expires_at': DateTime.now()
                          .subtract(const Duration(seconds: 1))
                          .toUtc()
                          .toIso8601String(),
                    },
                  ),
                ),
              ),
              child: const Text('Open call'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open call'));
    await tester.pumpAndSettle();

    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(find.text('Open call'), findsOneWidget);
  });

  testWidgets('ringing closes at local expiry when status cannot be fetched', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => IncomingCallScreen(
                    callData: {
                      'call_id': 'unreachable-call',
                      'call_token': 'unreachable-token',
                      'expires_at': DateTime.now()
                          .add(const Duration(seconds: 3))
                          .toUtc()
                          .toIso8601String(),
                    },
                  ),
                ),
              ),
              child: const Text('Open call'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open call'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(IncomingCallScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(IncomingCallScreen), findsNothing);
  });
}

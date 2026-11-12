import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkingmudde/widgets/aadhaar_verification_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _page() => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showAadhaarVerification(context, 42),
        child: const Text('Verify Aadhaar'),
      ),
    ),
  ),
);

http.Response _status(String status, {String? url}) => http.Response(
  jsonEncode({
    'success': true,
    'verification_status': status,
    if (url != null) 'verification_url': url,
  }),
  200,
);

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'BACKEND_URL=http://localhost:8000');
    SharedPreferences.setMockInitialValues({'session_token': 'test-session'});
  });

  testWidgets(
    'Starts and checks only on explicit actions, then reuses status',
    (tester) async {
      const link = 'https://ovse-test.surepass.in/launch?id=mock';
      final actions = <String>[];
      var saved = _status('not_started');
      await http.runWithClient(
        () async {
          await tester.pumpWidget(_page());
          await tester.tap(find.text('Verify Aadhaar'));
          await tester.pumpAndSettle();
          expect(actions, ['state']);

          await tester.tap(find.text('Start verification'));
          await tester.pumpAndSettle();
          expect(actions, ['state', 'start']);
          expect(find.text('Open Surepass'), findsOneWidget);

          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Verify Aadhaar'));
          await tester.pumpAndSettle();
          expect(actions, ['state', 'start', 'state']);
          expect(find.text('Open Surepass'), findsOneWidget);

          await tester.tap(find.text('Check verification'));
          await tester.pumpAndSettle();
          expect(
            find.text('Your Aadhaar verification is complete.'),
            findsOneWidget,
          );
          expect(find.text('Open Surepass'), findsNothing);

          await tester.tap(find.text('Done'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Verify Aadhaar'));
          await tester.pumpAndSettle();
          expect(actions, ['state', 'start', 'state', 'check', 'state']);
          expect(
            find.text('Your Aadhaar verification is complete.'),
            findsOneWidget,
          );
        },
        () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer test-session');
          expect(jsonDecode(request.body), {'user_id': 42});
          final action = request.url.pathSegments.last;
          actions.add(action);
          if (action == 'start') saved = _status('pending', url: link);
          if (action == 'check') saved = _status('verified');
          return saved;
        }),
      );
    },
  );

  testWidgets('Shows a spending denial and lets the user leave', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(_page());
        await tester.tap(find.text('Verify Aadhaar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start verification'));
        await tester.pumpAndSettle();
        expect(find.text('Verification call limit reached'), findsOneWidget);
        expect(find.text('Open Surepass'), findsNothing);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Aadhaar verification'), findsNothing);
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('/state')) return _status('not_started');
        return http.Response(
          '{"detail":"Verification call limit reached"}',
          429,
        );
      }),
    );
  });
}

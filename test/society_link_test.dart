import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkingmudde/screen/account/accountpage.dart';
import 'package:parkingmudde/screen/homepage/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profile = {
  'success': true,
  'user_id': 42,
  'full_name': 'Asha Patel',
  'mobile_number': '9876543210',
  'email': 'asha@example.com',
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'BACKEND_URL=http://localhost:8000');
    SharedPreferences.setMockInitialValues({'user_id': '42'});
  });

  testWidgets('Home submits a resident application and shows it as pending', (
    tester,
  ) async {
    Map<String, dynamic>? application;
    addTearDown(tester.view.resetViewInsets);

    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Homepage()));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        final link = find.text('Link My Society');
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select Society'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Green Valley').last);
        await tester.pumpAndSettle();

        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        final unitField = find.widgetWithText(TextFormField, 'Flat / Unit');
        await tester.ensureVisible(unitField);
        await tester.enterText(unitField, 'A-101');
        await tester.pumpAndSettle();
        final send = find.text('Send Request');
        await tester.ensureVisible(send);
        await tester.tap(send);
        await tester.pumpAndSettle();

        expect(application, containsPair('society_id', 'green-valley'));
        expect(application, containsPair('unit_number', 'A-101'));
        expect(
          find.text(
            'Your society access request is waiting for admin approval.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Society Request Pending'), findsOneWidget);
        expect(link, findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((request) async {
        switch (request.url.path) {
          case '/v1/auth/user/42':
            if (request.method == 'PUT') {
              application = jsonDecode(request.body) as Map<String, dynamic>;
              return _json({..._profile, 'society_id': 'green-valley'});
            }
            return _json(_profile);
          case '/v1/auth/user/42/community':
            return _json({'linked': false, 'pending': application != null});
          case '/v1/societies':
            return _json([
              {'id': 'green-valley', 'name': 'Green Valley'},
            ]);
          default:
            return _json({'detail': 'Not found'}, 404);
        }
      }),
    );
  });

  testWidgets('My Profile opens Aadhaar verification directly', (tester) async {
    var opened = false;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Accountpage()));
        await tester.pumpAndSettle();

        final aadhaar = find.text('Verify Aadhaar');
        await tester.ensureVisible(aadhaar);
        await tester.tap(aadhaar);
        await tester.pumpAndSettle();

        expect(opened, isTrue);
        expect(find.text('Aadhaar verification'), findsOneWidget);
        expect(find.text('Start verification'), findsOneWidget);
      },
      () => MockClient((request) async {
        switch (request.url.path) {
          case '/v1/auth/user/42':
            return _json(_profile);
          case '/v1/surepass/aadhaar/ovse/state':
            opened = true;
            expect(jsonDecode(request.body), {'user_id': 42});
            return _json({
              'success': true,
              'verification_status': 'not_started',
            });
          default:
            return _json({'detail': 'Not found'}, 404);
        }
      }),
    );
  });

  testWidgets('My Profile opens the onboarding form when the list is empty', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Accountpage()));
        await tester.pumpAndSettle();

        final link = find.text('Link My Society');
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();

        expect(
          find.text('No registered societies are available.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Society not listed? Apply to register it'));
        await tester.pumpAndSettle();

        expect(find.text('Suggest a Society'), findsOneWidget);
        expect(find.text('Submit Suggestion'), findsOneWidget);
      },
      () => MockClient((request) async {
        switch (request.url.path) {
          case '/v1/auth/user/42':
            return _json(_profile);
          case '/v1/auth/user/42/community':
            return _json({'linked': false});
          case '/v1/societies':
            return _json([]);
          default:
            return _json({'detail': 'Not found'}, 404);
        }
      }),
    );
  });
}

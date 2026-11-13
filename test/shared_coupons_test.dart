import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkingmudde/screen/account/editpage.dart';
import 'package:parkingmudde/screen/auth/loginpage.dart';
import 'package:parkingmudde/screen/auth/otppage.dart';
import 'package:parkingmudde/screen/auth/permissionspage.dart';
import 'package:parkingmudde/screen/auth/signinpage.dart';
import 'package:parkingmudde/screen/auth/user_state_picker.dart';
import 'package:parkingmudde/screen/couponstore/couponsstorepage.dart';
import 'package:parkingmudde/widgets/user_state_field.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'BACKEND_URL=http://localhost:8000');
    SharedPreferences.setMockInitialValues({
      'user_id': '42',
      'session_token': 'test-session',
    });
  });

  testWidgets('Email login continues without prompting for state', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const GetMaterialApp(home: Loginpage()));
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'resident@example.com');
        await tester.enterText(fields.at(1), 'test-password');
        final signIn = find.widgetWithText(ElevatedButton, 'Sign in');
        await tester.ensureVisible(signIn);
        await tester.tap(signIn);
        await tester.pumpAndSettle();

        expect(find.byType(PermissionsPage), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
      () => MockClient((request) async {
        expect(request.url.path, '/v1/auth/login');
        return http.Response(
          '{"success":true,"user_id":"42","state":null}',
          200,
        );
      }),
    );
  });

  testWidgets(
    'Phone login displays the temporary code and verifies it',
    (tester) async {
      final paths = <String>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const GetMaterialApp(home: Loginpage()));
          await tester.tap(find.text('Phone'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), '9000000001');
          final sendOtp = find.widgetWithText(ElevatedButton, 'Send OTP');
          await tester.ensureVisible(sendOtp);
          await tester.tap(sendOtp);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(Otppage), findsOneWidget);
          expect(find.text('012345'), findsOneWidget);
          await tester.enterText(
            find.descendant(
              of: find.byType(Pinput),
              matching: find.byType(EditableText),
            ),
            '012345',
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.byType(PermissionsPage), findsOneWidget);
          expect(paths, ['/v1/auth/send-otp', '/v1/auth/verify-otp']);
        },
        () => MockClient((request) async {
          paths.add(request.url.path);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['mobile_number'], '9000000001');
          if (request.url.path == '/v1/auth/send-otp') {
            return http.Response('{"success":true,"otp":"012345"}', 200);
          }
          expect(body['otp_code'], '012345');
          return http.Response(
            '{"success":true,"user_id":"42","session_token":"test-session"}',
            200,
          );
        }),
      );
    },
  );

  testWidgets(
    'Create Account offers state inline and Edit Profile loads and clears it',
    (tester) async {
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
          await tester.pumpAndSettle();
          final stateField = find.byType(UserStateField);
          expect(tester.widget<UserStateField>(stateField).value, isNull);
          expect(find.byType(AlertDialog), findsNothing);

          await tester.pumpWidget(
            const MaterialApp(key: ValueKey('edit'), home: EditProfilePage()),
          );
          await tester.pumpAndSettle();
          expect(tester.widget<UserStateField>(stateField).value, 'Delhi');
          await tester.ensureVisible(stateField);
          await tester.tap(
            find.descendant(
              of: stateField,
              matching: find.byType(DropdownButtonFormField<String>),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('No state selected').last);
          await tester.pumpAndSettle();
          expect(tester.widget<UserStateField>(stateField).value, isNull);
        },
        () => MockClient((request) async {
          final body = switch (request.url.path) {
            '/v1/auth/states' => '["Delhi","Goa","Kerala"]',
            '/v1/societies' => '[]',
            '/v1/auth/user/42' =>
              '{"success":true,"user_id":"42","full_name":"Test Resident"}',
            '/v1/auth/user/42/state' => '{"state":"Delhi"}',
            '/v1/auth/user/42/community' => '{"linked":false}',
            _ => throw StateError('Unexpected request ${request.url.path}'),
          };
          return http.Response(body, 200);
        }),
      );
    },
  );

  testWidgets('State picker saves the selected union territory', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => showUserStatePicker(context),
                    child: const Text('Continue'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delhi').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save state'));
        await tester.pumpAndSettle();

        expect(saved, {'state': 'Delhi'});
        expect(
          (await SharedPreferences.getInstance()).getString('state'),
          'Delhi',
        );
        expect(find.text('Select your state'), findsNothing);
      },
      () => MockClient((request) async {
        if (request.url.path == '/v1/auth/states') {
          return http.Response(jsonEncode(['Delhi', 'Goa', 'Kerala']), 200);
        }
        expect(request.url.path, '/v1/auth/user/42/state');
        expect(request.headers['authorization'], 'Bearer test-session');
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(saved), 200);
      }),
    );
  });

  testWidgets(
    'Add Coupon submits selected states and shows the code in My Society',
    (tester) async {
      Map<String, dynamic>? shared;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: CouponStoreScreen(coinsbackBalance: 0)),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('Add Coupon'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Business or brand'),
            'Local Cafe',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Offer title'),
            'Free coffee',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Coupon code'),
            'COFFEE',
          );

          await tester.ensureVisible(find.text('Delhi'));
          await tester.tap(find.text('Delhi'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kerala'));
          await tester.pump();
          await tester.tap(find.text('Done (2)'));
          await tester.pumpAndSettle();

          final priority = find.text('Priority in My Society');
          await tester.ensureVisible(priority);
          await tester.tap(priority);
          final submit = find.text('Share Coupon');
          await tester.ensureVisible(submit);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(shared, containsPair('states', ['Delhi', 'Kerala']));
          expect(shared, containsPair('society_priority', true));
          final societyTab = find.text('My Society Coupons');
          await tester.ensureVisible(societyTab);
          await tester.tap(societyTab);
          await tester.pumpAndSettle();
          expect(find.text('Green Valley'), findsOneWidget);
          expect(find.text('COFFEE'), findsOneWidget);
          expect(find.text('Society priority'), findsOneWidget);
        },
        () => MockClient((request) async {
          switch (request.url.path) {
            case '/v1/auth/states':
              return http.Response(jsonEncode(['Delhi', 'Goa', 'Kerala']), 200);
            case '/v1/coupons/shared/42':
              expect(request.headers['authorization'], 'Bearer test-session');
              if (request.method == 'POST') {
                shared = jsonDecode(request.body) as Map<String, dynamic>;
                return http.Response('{"success":true}', 201);
              }
              return http.Response(
                jsonEncode({
                  'state': 'Delhi',
                  'society_name': 'Green Valley',
                  'regional_coupons': [],
                  'society_coupons': [if (shared != null) shared],
                }),
                200,
              );
            case '/v1/coupons/':
            case '/v1/coupons/my/42':
              return http.Response('[]', 200);
            default:
              return http.Response('{"detail":"Not found"}', 404);
          }
        }),
      );
    },
  );
}

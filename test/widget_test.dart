import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parkingmudde/main.dart';
import 'package:parkingmudde/screen/splash/splashpage.dart';

void main() {
  testWidgets('app shell renders the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Splashpage), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homie_app/main.dart';

void main() {
  testWidgets('Homie app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HomieApp());

    // Verify that our app has the correct title.
    expect(find.text('Homie'), findsOneWidget);
    expect(find.text('Home Management System'), findsOneWidget);

    // Verify that module cards are present.
    expect(find.text('File Organizer'), findsOneWidget);
    expect(find.text('Financial Manager'), findsOneWidget);
  });
}

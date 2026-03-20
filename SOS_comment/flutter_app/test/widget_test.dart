// This file is intentionally kept minimal.
// The app entry point is ReviewGuardApp, not MyApp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_guard/main.dart';

void main() {
  testWidgets('ReviewGuardApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReviewGuardApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

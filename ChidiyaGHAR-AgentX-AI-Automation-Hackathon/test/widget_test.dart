import 'package:flutter_test/flutter_test.dart';
import 'package:health_ai/main.dart';
import 'package:health_ai/features/auth/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows app name', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthApp());

    // Verify that Splash Screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('VitaAI'), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:garith/main.dart';
import 'package:garith/services/auth_service.dart';

void main() {
  testWidgets('App boots to login when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: AuthService(),
        child: const GarithApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Garith'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

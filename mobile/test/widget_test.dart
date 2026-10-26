import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('shows the designed login screen', (tester) async {
    await tester.pumpWidget(const FuneralSpacesApp());

    expect(find.text('EverBond'), findsOneWidget);
    expect(find.text('Together, with care'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email or username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Contact your administrator'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(const FuneralSpacesApp());

    final passwordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('password-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    final visiblePasswordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('password-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(visiblePasswordField.obscureText, isFalse);
  });

  testWidgets('empty login fields show validation messages', (tester) async {
    await tester.pumpWidget(const FuneralSpacesApp());

    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email or username'), findsNWidgets(2));
    expect(find.text('Enter your password'), findsNWidgets(2));
  });

  testWidgets('valid-looking login explains authentication is not connected',
      (tester) async {
    await tester.pumpWidget(const FuneralSpacesApp());

    await tester.enterText(
      find.byKey(const Key('identity-field')),
      'member@example.org',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'not-a-real-password');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pump();

    expect(find.text('Sign-in is not connected yet.'), findsOneWidget);
  });
}

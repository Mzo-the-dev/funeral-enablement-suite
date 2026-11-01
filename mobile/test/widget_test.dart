import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/access_flow.dart';
import 'package:mobile/main.dart';
import 'package:mobile/registration_api.dart';

class _FakeRegistrationApi extends RegistrationApi {
  const _FakeRegistrationApi();

  static bool verifyCalled = false;

  @override
  Future<Map<String, dynamic>> register(Map<String, Object?> payload) async => {
    'registrationId': '00000000-0000-4000-8000-000000000001',
    'status': 'pending_verification',
    'channel': payload['verificationChannel'],
    'destination': 'a•••@example.org',
    'otpForDevelopment': '123456',
  };

  @override
  Future<Map<String, dynamic>> verify({
    required String registrationId,
    required String code,
  }) async {
    verifyCalled = true;
    return {'status': 'active', 'message': 'Contact verified.'};
  }
}

void main() {
  void useTallTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('starts with username and password login and a signup link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FuneralSpacesApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email or username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect(find.byKey(const Key('forgot-password-button')), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
    expect(find.text('Email code'), findsNothing);

    final passwordRect = tester.getRect(
      find.byKey(const Key('password-field')),
    );
    final forgotRect = tester.getRect(
      find.byKey(const Key('forgot-password-button')),
    );
    final loginRect = tester.getRect(find.byKey(const Key('login-button')));
    expect(forgotRect.right, closeTo(passwordRect.right, 1));
    expect(forgotRect.top, greaterThanOrEqualTo(passwordRect.bottom));
    expect(loginRect.top, greaterThanOrEqualTo(forgotRect.bottom));
  });

  testWidgets('signup link still opens the registration form', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FuneralSpacesApp());
    await tester.tap(find.byKey(const Key('open-registration')));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
    expect(find.byKey(const Key('registration-name')), findsOneWidget);
    expect(find.byKey(const Key('registration-space')), findsOneWidget);
  });

  testWidgets('registration contains the requested account fields', (
    tester,
  ) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: RegistrationScreen()));

    expect(find.text('Create your account'), findsOneWidget);
    for (final key in [
      'registration-name',
      'registration-surname',
      'registration-location',
      'registration-space',
      'registration-email',
      'registration-phone',
      'registration-address',
      'registration-preferred-name',
      'registration-username',
      'registration-password',
      'registration-confirm-password',
    ]) {
      final field = find.byKey(Key(key));
      await tester.scrollUntilVisible(
        field,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(field, findsOneWidget);
    }
  });

  testWidgets('space selection displays its tailored registration question', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegistrationScreen()));

    await tester.tap(find.byKey(const Key('registration-space')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supplier Space').last);
    await tester.pumpAndSettle();

    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Products or services you provide'), findsOneWidget);
  });

  testWidgets(
    'registration validates required fields before opening OTP screen',
    (tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(home: RegistrationScreen(api: _FakeRegistrationApi())),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('registration-continue')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('registration-continue')));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter your surname'), findsOneWidget);
      expect(find.text('Select a Space'), findsOneWidget);
      expect(find.byKey(const Key('registration-otp')), findsNothing);
    },
  );

  testWidgets(
    'valid registration details call the API and open code verification',
    (tester) async {
      _FakeRegistrationApi.verifyCalled = false;
      useTallTestViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(home: RegistrationScreen(api: _FakeRegistrationApi())),
      );

      Future<void> fill(String key, String value) async {
        final field = find.byKey(Key(key));
        await tester.scrollUntilVisible(
          field,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field, value);
      }

      await fill('registration-name', 'Amahle');
      await fill('registration-surname', 'Dlamini');
      await fill('registration-location', 'Durban');
      await tester.scrollUntilVisible(
        find.byKey(const Key('registration-space')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('registration-space')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Society Space').last);
      await tester.pumpAndSettle();
      await fill('registration-space-question-0', 'Example Society');
      await fill('registration-space-question-1', 'Member');
      await fill('registration-email', 'amahle@example.org');
      await fill('registration-phone', '0821234567');
      await fill('registration-address', '10 Example Road');
      await fill('registration-preferred-name', 'Ama');
      await fill('registration-username', 'amahle.dlamini');
      await fill('registration-password', 'safe-password-123');
      await fill('registration-confirm-password', 'safe-password-123');

      await tester.scrollUntilVisible(
        find.byKey(const Key('registration-continue')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('registration-continue')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm your email'), findsOneWidget);
      expect(find.byKey(const Key('registration-otp')), findsOneWidget);
      expect(
        find.text('Development code: 123456'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('registration-otp')), '123456');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('registration-verify'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('registration-verify')));
      await tester.pumpAndSettle();

      expect(_FakeRegistrationApi.verifyCalled, isTrue);
    },
  );
}

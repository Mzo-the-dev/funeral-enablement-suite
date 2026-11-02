import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/access_flow.dart';
import 'package:mobile/main.dart';
import 'package:mobile/registration_api.dart';

class _FakeRegistrationApi extends RegistrationApi {
  const _FakeRegistrationApi();

  static bool verifyCalled = false;
  static bool loginCalled = false;
  static bool logoutCalled = false;
  static String? loginIdentity;

  @override
  Future<Map<String, dynamic>> login({
    required String identity,
    required String password,
  }) async {
    loginCalled = true;
    loginIdentity = identity;
    return {'sessionToken': 'test-session-token'};
  }

  @override
  Future<void> logout(String sessionToken) async {
    logoutCalled = true;
  }

  @override
  Future<List<Map<String, dynamic>>> listSpaceTypes() async => [
    {'code': 'society', 'display_name': 'Society Space'},
    {'code': 'parlour', 'display_name': 'Parlour Space'},
    {'code': 'family', 'display_name': 'Family Space'},
    {'code': 'supplier', 'display_name': 'Supplier Space'},
  ];

  @override
  Future<List<Map<String, dynamic>>> listDiscoverableSpaces() async => [
    {
      'space_id': 'demo-space-id',
      'display_name': 'Stronger Together Society',
      'space_code': 'society',
      'public_description': 'A synthetic demo Society Space.',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> listMySpaces(String sessionToken) async =>
      [];

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

class _ActiveMembershipApi extends _FakeRegistrationApi {
  const _ActiveMembershipApi();

  @override
  Future<List<Map<String, dynamic>>> listMySpaces(String sessionToken) async =>
      [
        {
          'space_id': 'demo-space-id',
          'display_name': 'Stronger Together Society',
          'society_name': 'Stronger Together Society',
          'space_code': 'society',
          'role_code': 'member',
          'member_number': 'STS-036',
          'joined_at': '2026-11-02',
          'covered_life_count': 0,
        },
      ];
}

class _DashboardApi extends _ActiveMembershipApi {
  const _DashboardApi({
    this.canApproveCases = false,
    this.canApproveMemberships = false,
  });

  final bool canApproveCases;
  final bool canApproveMemberships;

  @override
  Future<Map<String, dynamic>> getSocietyDashboard({
    required String spaceId,
    required String sessionToken,
  }) async => {
    'society': {
      'space_id': spaceId,
      'society_name': 'Stronger Together Society',
    },
    'current_member': {
      'member_number': 'STS-036',
      'given_name': 'Amahle',
      'role_code': 'member',
      'office_roles': [
        if (canApproveCases) 'funeral_approver',
        if (canApproveMemberships) 'chairperson',
      ],
    },
    'permissions': {
      'can_approve_funeral_cases': canApproveCases,
      'can_approve_memberships': canApproveMemberships,
    },
    'summary': {
      'period_start': '2026-10-01',
      'active_members': 26,
      'deactivated_members': 10,
      'covered_lives': 250,
      'total_due': 6500,
      'total_collected': 6000,
      'outstanding': 500,
      'members_in_arrears': 2,
      'pending_cases': 2,
      'approved_cases': 1,
      'monthly_contribution': 250,
      'joining_fee': 1000,
    },
    'members': [
      {
        'member_number': 'STS-007',
        'given_name': 'Lindiwe',
        'surname': 'Mokoena',
        'status': 'active',
        'covered_lives': 2,
        'arrears_amount': 250,
        'is_in_arrears': true,
      },
      {
        'member_number': 'STS-036',
        'given_name': 'Amahle',
        'surname': 'Dlamini',
        'status': 'active',
        'covered_lives': 0,
        'arrears_amount': 0,
        'is_in_arrears': false,
      },
      {
        'member_number': 'STS-026',
        'given_name': 'Thandi',
        'surname': 'Ndlovu',
        'status': 'deactivated',
        'covered_lives': 0,
        'arrears_amount': 0,
        'is_in_arrears': false,
      },
    ],
    'my_contributions': [
      {
        'period_start': '2026-10-01',
        'amount_due': 250,
        'amount_paid': 250,
        'status': 'paid',
      },
    ],
    'funeral_cases': [
      {
        'funeral_case_id': 'case-pending',
        'case_reference': 'STS-FC-002',
        'status': 'pending',
        'summary': 'Awaiting approver review.',
        'member_number': 'STS-007',
        'given_name': 'Lindiwe',
        'surname': 'Mokoena',
      },
      {
        'funeral_case_id': 'case-approved',
        'case_reference': 'STS-FC-001',
        'status': 'approved',
        'summary': 'Approved for demo review.',
        'member_number': 'STS-004',
        'given_name': 'Sipho',
        'surname': 'Khumalo',
      },
    ],
    'membership_requests': canApproveMemberships
        ? [
            {
              'membership_request_id': 'request-1',
              'requested_member_number': 'STS-040',
              'given_name': 'Nandi',
              'surname': 'Zwane',
            },
          ]
        : <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>> approveMembershipRequest({
    required String spaceId,
    required String requestId,
    required String sessionToken,
  }) async => {'status': 'active'};

  @override
  Future<Map<String, dynamic>> approveFuneralCase({
    required String spaceId,
    required String caseId,
    required String sessionToken,
  }) async => {'status': 'approved'};
}

void main() {
  void useTallTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('society greeting follows local time-of-day boundaries', () {
    expect(societyGreetingFor(DateTime(2026, 11, 2, 0)), 'Good morning');
    expect(societyGreetingFor(DateTime(2026, 11, 2, 11, 59)), 'Good morning');
    expect(societyGreetingFor(DateTime(2026, 11, 2, 12)), 'Good afternoon');
    expect(societyGreetingFor(DateTime(2026, 11, 2, 17, 59)), 'Good afternoon');
    expect(societyGreetingFor(DateTime(2026, 11, 2, 18)), 'Good evening');
  });

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

  testWidgets('login opens the Spaces hub and signs out', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _FakeRegistrationApi.loginCalled = false;
    _FakeRegistrationApi.logoutCalled = false;
    _FakeRegistrationApi.loginIdentity = null;

    await tester.pumpWidget(
      const FuneralSpacesApp(api: _FakeRegistrationApi()),
    );
    await tester.enterText(
      find.byKey(const Key('identity-field')),
      'amahle@example.org',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'safe-password-123',
    );
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(_FakeRegistrationApi.loginCalled, isTrue);
    expect(_FakeRegistrationApi.loginIdentity, 'amahle@example.org');
    expect(find.text('Spaces & offerings'), findsOneWidget);
    expect(find.text('Your space'), findsOneWidget);
    expect(find.text('0 accessible'), findsOneWidget);
    expect(find.text('No active Spaces yet'), findsOneWidget);
    expect(find.text('Society Space'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('space-offer-society')),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('spaces-tab-content')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('space-offer-society')));
    await tester.pumpAndSettle();
    expect(find.text('Explore societies'), findsOneWidget);
    expect(find.text('Stronger Together Society'), findsOneWidget);
    expect(find.byKey(const Key('society-logo-demo-space-id')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('request-society-access-demo-space-id')),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Access requests are not connected yet'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('navigation-invitations')));
    await tester.pumpAndSettle();
    expect(find.text('No invitations yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('navigation-help')));
    await tester.pumpAndSettle();
    expect(find.text('Spaces stay separate'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.logoutCalled, isTrue);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('shows the linked society as an active Space', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SpacesLandingScreen(
          api: _DashboardApi(),
          sessionToken: 'test-session-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 accessible'), findsOneWidget);
    expect(find.byKey(const Key('active-space-demo-space-id')), findsOneWidget);
    expect(find.text('Stronger Together Society'), findsOneWidget);
    expect(find.text('Access enabled'), findsOneWidget);
    expect(find.text('Open Stronger Together Society'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Explore other offerings'),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('spaces-tab-content')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('offering-card-society')), findsNothing);

    await tester.tap(find.byKey(const Key('open-space-demo-space-id')));
    await tester.pumpAndSettle();
    expect(find.byType(SocietySpaceScreen), findsOneWidget);
    expect(find.textContaining(', Amahle'), findsOneWidget);
    expect(find.text('At a glance'), findsOneWidget);
    expect(find.text('October 2026 contributions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('society-tab-members')));
    await tester.pumpAndSettle();
    expect(find.text('Lindiwe Mokoena'), findsOneWidget);
    expect(find.text('Thandi Ndlovu'), findsOneWidget);
    expect(find.text('Deactivated'), findsWidgets);
    expect(find.text('In arrears · R250.00'), findsOneWidget);
    expect(find.byKey(const Key('society-member-search')), findsOneWidget);

    await tester.tap(find.byKey(const Key('society-tab-contributions')));
    await tester.pumpAndSettle();
    expect(find.text('R6000.00 of R6500.00'), findsOneWidget);
    expect(find.text('Your contribution history'), findsOneWidget);
    expect(find.text('R250.00 paid of R250.00'), findsOneWidget);
    expect(find.text('Lindiwe Mokoena'), findsNothing);

    await tester.tap(find.byKey(const Key('society-tab-cases')));
    await tester.pumpAndSettle();
    expect(find.text('STS-FC-002'), findsOneWidget);
    expect(find.text('STS-FC-001'), findsOneWidget);
    expect(find.byKey(const Key('approve-case-case-pending')), findsNothing);

    await tester.tap(find.byKey(const Key('society-tab-more')));
    await tester.pumpAndSettle();
    expect(find.text('STS-036'), findsOneWidget);
    expect(find.text('R1000.00'), findsOneWidget);
    expect(find.text('Membership applications'), findsNothing);
  });

  testWidgets('office approvals are limited to their assigned roles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> openDashboard(_DashboardApi api) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SocietySpaceScreen(
            key: ValueKey(
              '${api.canApproveCases}-${api.canApproveMemberships}',
            ),
            space: {
              'space_id': 'demo-space-id',
              'society_name': 'Stronger Together Society',
              'role_code': 'member',
              'joined_at': '2026-11-02',
            },
            api: api,
            sessionToken: 'test-session-token',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openDashboard(const _DashboardApi(canApproveCases: true));
    await tester.tap(find.byKey(const Key('society-tab-cases')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approve-case-case-pending')), findsOneWidget);
    await tester.tap(find.byKey(const Key('society-tab-more')));
    await tester.pumpAndSettle();
    expect(find.text('Membership applications'), findsNothing);
    expect(find.byKey(const Key('approve-membership-request-1')), findsNothing);

    await openDashboard(const _DashboardApi(canApproveMemberships: true));
    await tester.tap(find.byKey(const Key('society-tab-cases')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approve-case-case-pending')), findsNothing);
    await tester.tap(find.byKey(const Key('society-tab-more')));
    await tester.pumpAndSettle();
    expect(find.text('Membership applications'), findsOneWidget);
    expect(
      find.byKey(const Key('approve-membership-request-1')),
      findsOneWidget,
    );
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
        const MaterialApp(
          home: RegistrationScreen(api: _FakeRegistrationApi()),
        ),
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
        const MaterialApp(
          home: RegistrationScreen(api: _FakeRegistrationApi()),
        ),
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
      expect(find.text('Development code: 123456'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('registration-otp')),
        '123456',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('registration-verify')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('registration-verify')));
      await tester.pumpAndSettle();

      expect(_FakeRegistrationApi.verifyCalled, isTrue);
    },
  );
}

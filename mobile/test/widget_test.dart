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
  static bool profileUpdateCalled = false;
  static bool memberCreateCalled = false;
  static bool coveredLifeCreateCalled = false;
  static Map<String, Object?>? coveredLifeRegistration;
  static bool funeralCaseCreateCalled = false;
  static bool funeralPayoutCompleteCalled = false;
  static Map<String, Object?>? funeralCaseRegistration;
  static String preferredName = 'Amahle';
  static String? loginIdentity;
  static bool isPlatformAdmin = false;
  static bool platformAdminLinkCalled = false;

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
  Future<Map<String, dynamic>> getMyProfile(String sessionToken) async => {
    'given_name': 'Amahle',
    'preferred_name': preferredName,
    'avatar_base64': null,
    'avatar_mime_type': null,
    'is_platform_admin': isPlatformAdmin,
  };

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String sessionToken,
    required Map<String, Object?> changes,
  }) async {
    profileUpdateCalled = true;
    preferredName = changes['preferredName'] as String? ?? preferredName;
    return {
      'given_name': 'Amahle',
      'preferred_name': preferredName,
      'avatar_base64': null,
      'avatar_mime_type': null,
      'is_platform_admin': isPlatformAdmin,
    };
  }

  @override
  Future<Map<String, dynamic>> previewPlatformAdminMemberLink({
    required String sessionToken,
    required String identity,
    required String societyCode,
    required String memberNumber,
  }) async => {
    'account': {'given_name': 'Amahle', 'surname': 'Dlamini'},
    'member': {
      'member_number': memberNumber,
      'given_name': 'Synthetic Member',
      'surname': '001',
    },
    'society': {'name': 'Stronger Together Society'},
    'space': {'display_name': 'Stronger Together Society'},
    'already_linked': false,
  };

  @override
  Future<Map<String, dynamic>> repairPlatformAdminMemberLink({
    required String sessionToken,
    required String identity,
    required String societyCode,
    required String memberNumber,
    required String reason,
  }) async {
    platformAdminLinkCalled = true;
    return {'status': 'linked'};
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
    this.canManageMembers = false,
    this.canViewFinances = false,
    this.canViewCases = false,
    this.existingPayoutDetails,
  });

  final bool canApproveCases;
  final bool canApproveMemberships;
  final bool canManageMembers;
  final bool canViewFinances;
  final bool canViewCases;
  final Map<String, dynamic>? existingPayoutDetails;

  static int coveredLifeLimit = 10;
  static bool funeralPayoutCompleted = false;
  static String? pendingFuneralCoveredLifeName;
  static List<Map<String, dynamic>> coveredLives = [
    {
      'covered_life_id': 'covered-life-1',
      'person_number': 1,
      'display_name': 'Mia Dlamini',
      'relationship_code': 'dependent',
      'status': 'active',
      'effective_from': '2026-11-05',
    },
  ];

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
        if (canManageMembers) 'secretary',
        if (canViewFinances) 'treasurer',
        if (canApproveCases) 'funeral_approver',
        if (canApproveMemberships) 'chairperson',
      ],
    },
    'permissions': {
      'can_approve_funeral_cases': canApproveCases,
      'can_approve_memberships': canApproveMemberships,
      'can_manage_members': canManageMembers,
      'can_view_finances': canViewFinances,
      'can_view_cases': canViewCases || canApproveCases || canViewFinances,
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
    'recent_activity': [
      {
        'activity_type': 'contributions_received',
        'occurred_at': '2026-11-05T00:00:00.000Z',
        'event_count': 3,
        'amount': 1200,
      },
    ],
    'existing_payout_details': existingPayoutDetails,
    'members': [
      if (canManageMembers)
        {
          'member_id': 'member-007',
          'member_number': 'STS-007',
          'given_name': 'Lindiwe',
          'surname': 'Mokoena',
          'status': 'active',
          'covered_lives': 2,
          'arrears_amount': 250,
          'is_in_arrears': true,
        },
      {
        'member_id': 'member-036',
        'member_number': 'STS-036',
        'given_name': 'Amahle',
        'surname': 'Dlamini',
        'status': 'active',
        'covered_lives': 0,
        'arrears_amount': 0,
        'is_in_arrears': false,
      },
      if (canManageMembers)
        {
          'member_id': 'member-026',
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
    'funeral_cases': canViewCases || canApproveCases || canViewFinances
        ? [
            {
              'funeral_case_id': 'case-pending',
              'case_reference': 'STS-FC-002',
              'status': 'pending',
              'payout_status': 'not_started',
              'summary': 'Awaiting approver review.',
              'member_number': 'STS-007',
              'given_name': 'Lindiwe',
              'surname': 'Mokoena',
            },
            {
              'funeral_case_id': 'case-approved',
              'case_reference': 'STS-FC-001',
              'status': 'approved',
              'payout_status': _DashboardApi.funeralPayoutCompleted
                  ? 'completed'
                  : 'in_progress',
              'summary': 'Approved for demo review.',
              'member_number': 'STS-004',
              'given_name': 'Sipho',
              'surname': 'Khumalo',
            },
          ]
        : [
            {
              'funeral_case_id': 'case-mine',
              'case_reference': 'STS-FC-003',
              'status': 'pending',
              'payout_status': 'not_started',
              'summary': 'A funeral reported for my household.',
              'deceased_given_name': 'Amahle',
              'deceased_surname': 'Dlamini',
              'date_of_death': '2026-11-04',
              'member_number': 'STS-036',
              'given_name': 'Amahle',
              'surname': 'Dlamini',
            },
            if (_FakeRegistrationApi.funeralCaseCreateCalled)
              {
                'funeral_case_id': 'case-created',
                'case_reference': 'STS-FC-004',
                'status': 'pending',
                'payout_status': 'not_started',
                'summary': 'Awaiting approver review.',
                'deceased_given_name': 'Mia',
                'deceased_surname': 'Dlamini',
                'date_of_death': '2026-11-06',
                'member_number': 'STS-036',
                'given_name': 'Amahle',
                'surname': 'Dlamini',
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
  Future<List<Map<String, dynamic>>> listActiveSocietyMembers({
    required String spaceId,
    required String sessionToken,
  }) async => [
    {
      'member_id': 'member-007',
      'member_number': canManageMembers ? 'STS-007' : null,
      'given_name': 'Lindiwe',
      'surname': 'Mokoena',
      'status': 'active',
      'covered_lives': 2,
    },
    {
      'member_id': 'member-036',
      'member_number': canManageMembers ? 'STS-036' : null,
      'given_name': 'Amahle',
      'surname': 'Dlamini',
      'status': 'active',
      'covered_lives': coveredLives.length,
    },
  ];

  @override
  Future<Map<String, dynamic>> getMyCoveredLives({
    required String spaceId,
    required String sessionToken,
  }) async => {
    'member_id': 'member-036',
    'max_covered_lives_per_member': coveredLifeLimit,
    'active_covered_life_count': coveredLives
        .where((life) => life['status'] == 'active')
        .length,
    'covered_lives': coveredLives
        .map(
          (life) => {
            ...life,
            'has_pending_funeral_case':
                life['display_name'] == pendingFuneralCoveredLifeName,
          },
        )
        .toList(),
  };

  @override
  Future<Map<String, dynamic>> createMyCoveredLife({
    required String spaceId,
    required String sessionToken,
    required Map<String, Object?> coveredLife,
  }) async {
    _FakeRegistrationApi.coveredLifeCreateCalled = true;
    _FakeRegistrationApi.coveredLifeRegistration = coveredLife;
    final created = <String, dynamic>{
      'covered_life_id': 'covered-life-${coveredLives.length + 1}',
      'person_number': coveredLives.length + 1,
      'display_name': coveredLife['displayName'],
      'identity_number': coveredLife['identityNumber'],
      'relationship_code': coveredLife['relationshipCode'],
      'status': 'active',
      'effective_from': coveredLife['effectiveFrom'],
    };
    coveredLives = [...coveredLives, created];
    return created;
  }

  @override
  Future<Map<String, dynamic>> getSocietyMember({
    required String spaceId,
    required String memberId,
    required String sessionToken,
  }) async => {
    'member_id': memberId,
    'member_number': memberId == 'member-007' ? 'STS-007' : 'STS-036',
    'given_name': memberId == 'member-007' ? 'Lindiwe' : 'Amahle',
    'surname': memberId == 'member-007' ? 'Mokoena' : 'Dlamini',
    'status': 'active',
    'joined_at': '2026-11-02',
    'covered_lives': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>> createSocietyMember({
    required String spaceId,
    required String sessionToken,
    required Map<String, Object?> member,
  }) async {
    _FakeRegistrationApi.memberCreateCalled = true;
    return {'member_id': 'member-new', ...member};
  }

  @override
  Future<List<Map<String, dynamic>>> getSocietyMemberHistory({
    required String spaceId,
    required String memberId,
    required String sessionToken,
  }) async => [];

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

  @override
  Future<Map<String, dynamic>> completeFuneralCasePayout({
    required String spaceId,
    required String caseId,
    required String sessionToken,
  }) async {
    _FakeRegistrationApi.funeralPayoutCompleteCalled = true;
    _DashboardApi.funeralPayoutCompleted = true;
    return {'status': 'completed'};
  }

  @override
  Future<Map<String, dynamic>> registerFuneralCase({
    required String spaceId,
    required String sessionToken,
    required Map<String, Object?> registration,
  }) async {
    _FakeRegistrationApi.funeralCaseCreateCalled = true;
    _FakeRegistrationApi.funeralCaseRegistration = registration;
    _DashboardApi.pendingFuneralCoveredLifeName =
        '${registration['givenName']} ${registration['surname']}';
    return {
      'case_reference': 'STS-FC-004',
      'status': 'pending',
      'assigned_to': 'vice_chairperson',
    };
  }
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

  testWidgets('platform admin can review and confirm a scoped account link', (
    tester,
  ) async {
    _FakeRegistrationApi.isPlatformAdmin = true;
    _FakeRegistrationApi.platformAdminLinkCalled = false;
    addTearDown(() => _FakeRegistrationApi.isPlatformAdmin = false);
    await tester.pumpWidget(
      const MaterialApp(
        home: SpacesLandingScreen(
          api: _ActiveMembershipApi(),
          sessionToken: 'test-session-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('platform-admin-tools')), findsOneWidget);
    await tester.tap(find.byKey(const Key('platform-admin-tools')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-account-identity')),
      'synthetic001',
    );
    await tester.enterText(
      find.byKey(const Key('admin-society-code')),
      'STRONGER-TOGETHER-DEMO',
    );
    await tester.enterText(
      find.byKey(const Key('admin-member-number')),
      'STS-001',
    );
    await tester.enterText(
      find.byKey(const Key('admin-repair-reason')),
      'Bootstrap the verified chairperson account',
    );
    await tester.tap(find.byKey(const Key('review-member-account-link')));
    await tester.pumpAndSettle();
    expect(find.text('STS-001 · Synthetic Member 001'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit-member-account-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-member-account-link')));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.platformAdminLinkCalled, isTrue);
    expect(find.text('Account link repaired'), findsOneWidget);
  });

  testWidgets('ordinary account does not see platform admin repair tools', (
    tester,
  ) async {
    _FakeRegistrationApi.isPlatformAdmin = false;
    addTearDown(() => _FakeRegistrationApi.isPlatformAdmin = false);
    await tester.pumpWidget(
      const MaterialApp(
        home: SpacesLandingScreen(
          api: _ActiveMembershipApi(),
          sessionToken: 'test-session-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('platform-admin-tools')), findsNothing);
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
    _FakeRegistrationApi.profileUpdateCalled = false;
    _FakeRegistrationApi.memberCreateCalled = false;
    _FakeRegistrationApi.preferredName = 'Amahle';
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SpacesLandingScreen(
          api: _DashboardApi(
            canManageMembers: true,
            canViewFinances: true,
            canViewCases: true,
          ),
          sessionToken: 'test-session-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('preferred-name-field')),
      'Amahle Preferred',
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.profileUpdateCalled, isTrue);

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
    final bottomNavigation = find.byType(NavigationBar);
    expect(bottomNavigation, findsOneWidget);
    for (final icon in [
      Icons.home,
      Icons.groups_outlined,
      Icons.payments_outlined,
      Icons.assignment_outlined,
      Icons.more_horiz,
    ]) {
      expect(
        find.descendant(of: bottomNavigation, matching: find.byIcon(icon)),
        findsOneWidget,
      );
    }
    expect(find.textContaining(', Amahle Preferred'), findsOneWidget);
    await tester.tap(find.byKey(const Key('society-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preferred-name-field')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('At a glance'), findsOneWidget);
    expect(find.text('October 2026 contributions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('society-tab-members')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-society-member')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('member-number-field')),
      'STS-041',
    );
    await tester.enterText(
      find.byKey(const Key('member-given-name-field')),
      'Nandi',
    );
    await tester.enterText(
      find.byKey(const Key('member-surname-field')),
      'Zwane',
    );
    await tester.tap(find.byKey(const Key('save-society-member')));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.memberCreateCalled, isTrue);
    expect(find.text('Lindiwe Mokoena'), findsOneWidget);
    expect(find.text('Thandi Ndlovu'), findsNothing);
    expect(find.text('In arrears · R250.00'), findsNothing);
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

  testWidgets('ordinary members only see their own Society data', (
    tester,
  ) async {
    useTallTestViewport(tester);
    _DashboardApi.coveredLifeLimit = 10;
    _DashboardApi.pendingFuneralCoveredLifeName = null;
    _DashboardApi.coveredLives = [
      {
        'covered_life_id': 'covered-life-1',
        'person_number': 1,
        'display_name': 'Mia Dlamini',
        'relationship_code': 'dependent',
        'status': 'active',
        'effective_from': '2026-11-05',
      },
    ];
    _FakeRegistrationApi.coveredLifeCreateCalled = false;
    _FakeRegistrationApi.coveredLifeRegistration = null;
    await tester.pumpWidget(
      MaterialApp(
        home: SocietySpaceScreen(
          space: const {
            'space_id': 'demo-space-id',
            'society_name': 'Stronger Together Society',
            'role_code': 'member',
          },
          api: const _DashboardApi(
            existingPayoutDetails: {
              'bank_name': 'Capitec Bank',
              'account_name': 'Amahle Dlamini',
              'account_number': '1234567890',
            },
          ),
          sessionToken: 'test-session-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('At a glance'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('R6000.00'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('R1200.00 received'), findsOneWidget);
    expect(find.text('Lindiwe Mokoena'), findsNothing);
    expect(find.byKey(const Key('add-society-member')), findsNothing);

    await tester.tap(find.byKey(const Key('society-tab-members')));
    await tester.pumpAndSettle();
    expect(find.text('Amahle Dlamini'), findsOneWidget);
    expect(find.text('Lindiwe Mokoena'), findsOneWidget);
    expect(find.textContaining('arrears'), findsNothing);
    expect(find.text('Thandi Ndlovu'), findsNothing);

    await tester.tap(find.text('Show covered lives'));
    await tester.pumpAndSettle();
    expect(find.text('Mia Dlamini'), findsOneWidget);
    expect(find.text('1 of 10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-own-covered-life')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('own-covered-life-given-name')),
      'Lena',
    );
    await tester.enterText(
      find.byKey(const Key('own-covered-life-surname')),
      'Dlamini',
    );
    await tester.enterText(
      find.byKey(const Key('own-covered-life-id-number')),
      'A1234567',
    );
    await tester.tap(find.byKey(const Key('save-own-covered-life')));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.coveredLifeCreateCalled, isTrue);
    expect(
      _FakeRegistrationApi.coveredLifeRegistration,
      containsPair('displayName', 'Lena Dlamini'),
    );
    expect(
      _FakeRegistrationApi.coveredLifeRegistration,
      containsPair('identityNumber', 'A1234567'),
    );
    expect(
      _FakeRegistrationApi.coveredLifeRegistration,
      containsPair('relationshipCode', 'dependent'),
    );
    expect(find.text('Lena Dlamini'), findsOneWidget);
    expect(find.text('2 of 10'), findsOneWidget);

    _DashboardApi.coveredLifeLimit = 2;
    await tester.tap(find.text('Show society members'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show covered lives'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);
    expect(
      find.text('Your Society’s covered-life limit has been reached.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('add-own-covered-life')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('society-tab-contributions')));
    await tester.pumpAndSettle();
    expect(find.text('Society total'), findsNothing);
    expect(find.text('Your contribution history'), findsOneWidget);

    await tester.tap(find.byKey(const Key('society-tab-cases')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-funeral-case')), findsOneWidget);
    expect(find.text('STS-FC-003'), findsOneWidget);
    expect(find.text('Pending Approval'), findsOneWidget);
    expect(find.text('Deceased: Amahle Dlamini'), findsOneWidget);
    expect(find.textContaining('restricted'), findsNothing);
    expect(find.text('STS-FC-002'), findsNothing);
    expect(find.text('STS-FC-001'), findsNothing);

    await tester.tap(find.byKey(const Key('register-funeral-case')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Capitec Bank · Amahle Dlamini'),
      findsOneWidget,
    );
    expect(find.textContaining('Account 1234567890'), findsOneWidget);
    expect(find.byKey(const Key('payout-bank-field')), findsNothing);
    await tester.tap(find.byKey(const Key('enter-new-bank-details')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payout-bank-field')), findsOneWidget);
    expect(find.byKey(const Key('payout-account-name-field')), findsOneWidget);
    expect(
      find.byKey(const Key('payout-account-number-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('deceased-given-name-field')),
      'Mia',
    );
    await tester.enterText(
      find.byKey(const Key('deceased-surname-field')),
      'Dlamini',
    );
    await tester.enterText(
      find.byKey(const Key('date-of-death-field')),
      '2026-11-06',
    );
    await tester.tap(find.byKey(const Key('payout-bank-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FNB').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('payout-account-name-field')),
      'Mia Dlamini',
    );
    await tester.enterText(
      find.byKey(const Key('payout-account-number-field')),
      '9876543210',
    );
    await tester.tap(find.byKey(const Key('submit-funeral-case')));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.funeralCaseCreateCalled, isTrue);
    expect(
      _FakeRegistrationApi.funeralCaseRegistration,
      containsPair('givenName', 'Mia'),
    );
    expect(
      _FakeRegistrationApi.funeralCaseRegistration,
      containsPair('dateOfDeath', '2026-11-06'),
    );
    expect(
      _FakeRegistrationApi.funeralCaseRegistration,
      containsPair('bankName', 'FNB'),
    );
    expect(
      _FakeRegistrationApi.funeralCaseRegistration,
      containsPair('useExistingBankDetails', false),
    );
    expect(find.text('Funeral registered'), findsOneWidget);
    expect(
      find.text(
        'The funeral was successfully registered and is pending approval.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('society-tab-cases')));
    await tester.pumpAndSettle();
    expect(find.text('STS-FC-004'), findsOneWidget);
    expect(find.text('Pending Approval'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('society-tab-members')));
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('Funeral Pending'), findsOneWidget);
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
              '${api.canApproveCases}-${api.canApproveMemberships}-${api.canViewFinances}',
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

    _DashboardApi.funeralPayoutCompleted = false;
    _FakeRegistrationApi.funeralPayoutCompleteCalled = false;
    await openDashboard(const _DashboardApi(canViewFinances: true));
    await tester.tap(find.byKey(const Key('society-tab-cases')));
    await tester.pumpAndSettle();
    expect(find.text('In Progress'), findsOneWidget);
    await tester.tap(find.byKey(const Key('complete-payout-case-approved')));
    await tester.pumpAndSettle();
    expect(_FakeRegistrationApi.funeralPayoutCompleteCalled, isTrue);
    expect(find.text('Completed'), findsOneWidget);
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

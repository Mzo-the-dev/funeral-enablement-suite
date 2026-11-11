import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'access_flow.dart';
import 'registration_api.dart';

void main() {
  runApp(const FuneralSpacesApp());
}

String societyGreetingFor(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 18) return 'Good afternoon';
  return 'Good evening';
}

abstract final class AppColors {
  static const background = Color(0xFFF7F5EF);
  static const forest = Color(0xFF174B3A);
  static const ink = Color(0xFF252A27);
  static const muted = Color(0xFF606963);
  static const border = Color(0xFFD7DDD8);
  static const white = Color(0xFFFFFFFF);
}

class FuneralSpacesApp extends StatelessWidget {
  const FuneralSpacesApp({super.key, this.api = const RegistrationApi()});

  final RegistrationApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EverBond',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          primary: AppColors.forest,
          surface: AppColors.background,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.forest,
          selectionColor: Color(0x55174B3A),
          selectionHandleColor: AppColors.forest,
        ),
      ),
      home: LoginScreen(api: api),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.api = const RegistrationApi()});

  final RegistrationApi api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showNotConnectedMessage(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$action is not connected yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _submitLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await widget.api.login(
        identity: _identityController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final sessionToken = result['sessionToken'];
      if (sessionToken is! String || sessionToken.isEmpty) {
        throw const RegistrationApiException(
          'The server returned an invalid session.',
        );
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              SpacesLandingScreen(api: widget.api, sessionToken: sessionToken),
        ),
      );
    } on RegistrationApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 14, 32, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 38,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _EverBondBrand(),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome back',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.ink,
                        fontSize: 32,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Log in to manage your society and support the families in your care.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                        height: 1.55,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 27),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _FieldLabel('Email or username'),
                          const SizedBox(height: 9),
                          TextFormField(
                            key: const Key('identity-field'),
                            controller: _identityController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Enter your email or username',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your email or username'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Password'),
                          const SizedBox(height: 9),
                          TextFormField(
                            key: const Key('password-field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submitLogin(),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.muted,
                                  size: 22,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your password'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('forgot-password-button'),
                              onPressed: () =>
                                  _showNotConnectedMessage('Password recovery'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.forest,
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 10,
                                  bottom: 10,
                                ),
                                minimumSize: const Size(48, 40),
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              key: const Key('login-button'),
                              onPressed: _isSubmitting ? null : _submitLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.forest,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 21,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text('Log in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 27),
                    const _OrDivider(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialSignInButton(
                            label: 'Google',
                            icon: const _GoogleMark(),
                            onPressed: () =>
                                _showNotConnectedMessage('Google sign-in'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialSignInButton(
                            label: 'Facebook',
                            icon: const _FacebookMark(),
                            onPressed: () =>
                                _showNotConnectedMessage('Facebook sign-in'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Text(
                      'Need access to your society?',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      key: const Key('open-registration'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegistrationScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        minimumSize: const Size(48, 44),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Don't have an account? Sign up"),
                    ),
                    const Spacer(),
                    const SizedBox(height: 26),
                    const _PrivacyNote(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpacesLandingScreen extends StatefulWidget {
  const SpacesLandingScreen({
    super.key,
    required this.api,
    required this.sessionToken,
  });

  final RegistrationApi api;
  final String sessionToken;

  @override
  State<SpacesLandingScreen> createState() => _SpacesLandingScreenState();
}

class _SpacesLandingScreenState extends State<SpacesLandingScreen> {
  List<Map<String, dynamic>> _spaceTypes = [];
  List<Map<String, dynamic>> _discoverableSpaces = [];
  List<Map<String, dynamic>> _mySpaces = [];
  String? _loadError;
  bool _isLoading = true;
  bool _isSigningOut = false;
  int _selectedTab = 0;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadSpaceTypes();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.api.getMyProfile(widget.sessionToken);
      if (mounted) setState(() => _profile = profile);
    } on RegistrationApiException catch (error) {
      if (mounted) _showAccountMessage(error.message);
    }
  }

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProfileEditDialog(
        api: widget.api,
        sessionToken: widget.sessionToken,
        profile: _profile,
      ),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
  }

  void _showAccountMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadSpaceTypes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.api.listSpaceTypes(),
        widget.api.listDiscoverableSpaces(),
        widget.api.listMySpaces(widget.sessionToken),
      ]);
      if (mounted) {
        setState(() {
          _spaceTypes = results[0];
          _discoverableSpaces = results[1];
          _mySpaces = results[2];
        });
      }
    } on RegistrationApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.api.logout(widget.sessionToken);
    } on RegistrationApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not confirm sign-out with the server.'),
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(api: widget.api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SpacesBrandHeader(
              isSigningOut: _isSigningOut,
              avatarBytes: _decodeAvatar(_profile),
              onEditProfile: _editProfile,
              onSignOut: _signOut,
            ),
            _SpacesNavigation(
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildSpacesTab(),
                  _buildInvitationsTab(),
                  _buildHelpTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpacesTab() {
    return ListView(
      key: const Key('spaces-tab-content'),
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      children: [
        Text(
          'Spaces & offerings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Care, coordination and support. Find the right space for your role.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
        ),
        if (_profile['is_platform_admin'] == true) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('platform-admin-tools'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlatformAdminRepairScreen(
                    api: widget.api,
                    sessionToken: widget.sessionToken,
                  ),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text('Platform data repair'),
            ),
          ),
        ],
        const SizedBox(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your space',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _isLoading ? 'Loading' : '${_mySpaces.length} accessible',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const LinearProgressIndicator()
        else if (_loadError != null)
          Text(
            'Could not load your Spaces. ${_loadError!}',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          )
        else if (_mySpaces.isEmpty)
          Container(
            key: const Key('empty-memberships'),
            constraints: const BoxConstraints(minHeight: 65),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.groups_outlined, color: AppColors.muted, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No active Spaces yet',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'An account does not automatically grant Space access.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ..._mySpaces.map(_buildActiveSpace),
        const SizedBox(height: 8),
        const Text(
          'Explore other offerings',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'These aren’t enabled for your account. Access requires an invitation or approval.',
          style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_loadError != null)
          _SpaceTypesError(message: _loadError!, onRetry: _loadSpaceTypes)
        else if (_spaceTypes.isEmpty)
          const Text('No Space offerings are currently available.')
        else ...[
          ..._spaceTypes
              .where(
                (spaceType) => !_mySpaces.any(
                  (space) => space['space_code'] == spaceType['code'],
                ),
              )
              .map(_buildSpaceType),
          _sharedCaseCard(),
        ],
        const SizedBox(height: 12),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 9),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.forest, size: 13),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Separate spaces. Protected information. Access is approved for each Space.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvitationsTab() {
    return ListView(
      key: const Key('invitations-tab-content'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: const [
        Text(
          'Invitations',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Review invitations before joining a Space.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
        ),
        SizedBox(height: 24),
        Icon(
          Icons.mark_email_unread_outlined,
          color: AppColors.forest,
          size: 30,
        ),
        SizedBox(height: 9),
        Text(
          'No invitations yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Invitations sent to this account will appear here for your review.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildActiveSpace(Map<String, dynamic> space) {
    final spaceId = space['space_id'] as String? ?? '';
    final displayName = space['display_name'] as String? ?? 'Society Space';
    final societyName = space['society_name'] as String? ?? displayName;

    return Container(
      key: Key('active-space-$spaceId'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: AppColors.forest,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.forest,
                          size: 11,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Access enabled',
                          style: TextStyle(
                            color: AppColors.forest,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your membership is active in $societyName.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: FilledButton.icon(
              key: Key('open-space-$spaceId'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SocietySpaceScreen(
                    space: space,
                    api: widget.api,
                    sessionToken: widget.sessionToken,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: Text('Open $displayName'),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTab() {
    return ListView(
      key: const Key('help-tab-content'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: const [
        Text(
          'Help',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Your account and Space access',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
        ),
        SizedBox(height: 18),
        _HelpNote(
          icon: Icons.lock_outline,
          title: 'Spaces stay separate',
          body: 'Joining one Space does not automatically share your information with another.',
        ),
        SizedBox(height: 10),
        _HelpNote(
          icon: Icons.verified_user_outlined,
          title: 'Access needs approval',
          body: 'An invitation or approved request is required before private Space information is available.',
        ),
      ],
    );
  }

  Widget _buildSpaceType(Map<String, dynamic> spaceType) {
    final code = spaceType['code'] as String? ?? '';
    final displayName = spaceType['display_name'] as String? ?? code;
    final offering = _offeringFor(code, displayName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _OfferingCard(
        key: Key('offering-card-$code'),
        title: displayName,
        subtitle: 'Access required',
        description: offering.description,
        icon: offering.icon,
        actionLabel: 'Explore & request access',
        actionKey: Key('space-offer-$code'),
        onPressed: () {
          if (code == 'society') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SocietyDirectoryScreen(
                  spaces: _discoverableSpaces,
                  loadError: _loadError,
                  isLoading: _isLoading,
                  onRetry: _loadSpaceTypes,
                ),
              ),
            );
          } else {
            _showAccessInfo(displayName);
          }
        },
      ),
    );
  }

  Widget _sharedCaseCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _OfferingCard(
        key: const Key('shared-case-card'),
        title: 'Shared Funeral Case',
        subtitle: 'Invitation required',
        description: 'Invited participants coordinate case progress, checklists and updates in a permission-based workspace.',
        icon: Icons.assignment_outlined,
        actionLabel: 'How to get invited',
        actionKey: const Key('shared-case-invitation-help'),
        onPressed: _showInvitationInfo,
      ),
    );
  }

  void _showAccessInfo(String offeringName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offeringName),
        content: const Text(
          'Access requests are not connected yet. Choosing an offering does not create membership or grant access to private information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInvitationInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shared Funeral Case'),
        content: const Text(
          'A case coordinator must invite you before you can view or update a shared case.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class PlatformAdminRepairScreen extends StatefulWidget {
  const PlatformAdminRepairScreen({
    super.key,
    required this.api,
    required this.sessionToken,
  });

  final RegistrationApi api;
  final String sessionToken;

  @override
  State<PlatformAdminRepairScreen> createState() =>
      _PlatformAdminRepairScreenState();
}

class _PlatformAdminRepairScreenState extends State<PlatformAdminRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _societyCodeController = TextEditingController();
  final _memberNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  Map<String, dynamic>? _preview;
  bool _isBusy = false;

  @override
  void dispose() {
    _identityController.dispose();
    _societyCodeController.dispose();
    _memberNumberController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _reviewLink() async {
    if (_isBusy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isBusy = true);
    try {
      final preview = await widget.api.previewPlatformAdminMemberLink(
        sessionToken: widget.sessionToken,
        identity: _identityController.text.trim(),
        societyCode: _societyCodeController.text.trim(),
        memberNumber: _memberNumberController.text.trim(),
      );
      if (mounted) setState(() => _preview = preview);
    } on RegistrationApiException catch (error) {
      if (mounted) _showAdminMessage(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmLink() async {
    final preview = _preview;
    if (preview == null || _isBusy) return;
    final account = _platformAdminMap(preview['account']);
    final member = _platformAdminMap(preview['member']);
    final society = _platformAdminMap(preview['society']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm account link'),
        content: Text(
          'Link ${account['given_name']} ${account['surname']} to '
          '${member['member_number']} (${member['given_name']} ${member['surname']}) '
          'in ${society['name']} and activate its Society Space access?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-member-account-link'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm link'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await widget.api.repairPlatformAdminMemberLink(
        sessionToken: widget.sessionToken,
        identity: _identityController.text.trim(),
        societyCode: _societyCodeController.text.trim(),
        memberNumber: _memberNumberController.text.trim(),
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _preview = null);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account link repaired'),
          content: const Text(
            'The existing account is linked to the Society member and its active Society Space.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on RegistrationApiException catch (error) {
      if (mounted) _showAdminMessage(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showAdminMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final account = _preview == null
        ? <String, dynamic>{}
        : _platformAdminMap(_preview!['account']);
    final member = _preview == null
        ? <String, dynamic>{}
        : _platformAdminMap(_preview!['member']);
    final society = _preview == null
        ? <String, dynamic>{}
        : _platformAdminMap(_preview!['society']);
    final space = _preview == null
        ? <String, dynamic>{}
        : _platformAdminMap(_preview!['space']);
    final alreadyLinked = _preview?['already_linked'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Platform data repair')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Link an existing account to an existing Society member.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('admin-account-identity'),
                controller: _identityController,
                decoration: const InputDecoration(
                  labelText: 'Username or verified email',
                ),
                onChanged: (_) => setState(() => _preview = null),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Enter a username or verified email.'
                    : null,
              ),
              TextFormField(
                key: const Key('admin-society-code'),
                controller: _societyCodeController,
                decoration: const InputDecoration(labelText: 'Society code'),
                onChanged: (_) => setState(() => _preview = null),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a Society code.'
                    : null,
              ),
              TextFormField(
                key: const Key('admin-member-number'),
                controller: _memberNumberController,
                decoration: const InputDecoration(
                  labelText: 'Society member number',
                ),
                onChanged: (_) => setState(() => _preview = null),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a member number.'
                    : null,
              ),
              TextFormField(
                key: const Key('admin-repair-reason'),
                controller: _reasonController,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason for repair',
                ),
                validator: (value) => value == null || value.trim().length < 10
                    ? 'Enter a reason of at least 10 characters.'
                    : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('review-member-account-link'),
                onPressed: _isBusy ? null : _reviewLink,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(_isBusy ? 'Checking…' : 'Review link'),
              ),
              if (_preview != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('${account['given_name']} ${account['surname']}'),
                      const SizedBox(height: 10),
                      const Text(
                        'Society member',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${member['member_number']} · ${member['given_name']} ${member['surname']}',
                      ),
                      Text('${society['name']} · ${space['display_name']}'),
                      const SizedBox(height: 10),
                      Text(
                        alreadyLinked
                            ? 'This account and member are already linked.'
                            : 'Confirm only if these are the intended records.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('submit-member-account-link'),
                  onPressed: _isBusy || alreadyLinked ? null : _confirmLink,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Confirm and link'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _platformAdminMap(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

class SocietySpaceScreen extends StatefulWidget {
  const SocietySpaceScreen({
    super.key,
    required this.space,
    required this.api,
    required this.sessionToken,
  });

  final Map<String, dynamic> space;
  final RegistrationApi api;
  final String sessionToken;

  @override
  State<SocietySpaceScreen> createState() => _SocietySpaceScreenState();
}

class _SocietySpaceScreenState extends State<SocietySpaceScreen> {
  int _selectedTab = 0;
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _profile = {};
  String? _loadError;
  bool _isLoading = true;
  bool _isSigningOut = false;
  String _memberSearch = '';
  String _memberView = 'society-members';
  List<Map<String, dynamic>> _societyMembers = [];
  Map<String, dynamic> _myCoveredLifeData = {};
  bool _isLoadingMemberView = true;
  String? _memberViewError;
  int _memberViewRequest = 0;

  String get _spaceId => widget.space['space_id'] as String? ?? '';

  Map<String, dynamic> get _currentMember =>
      _asMap(_dashboard['current_member']);
  Map<String, dynamic> get _permissions => _asMap(_dashboard['permissions']);
  Map<String, dynamic> get _summary => _asMap(_dashboard['summary']);
  List<Map<String, dynamic>> get _recentActivity =>
      _asMaps(_dashboard['recent_activity']);
  List<Map<String, dynamic>> get _contributions =>
      _asMaps(_dashboard['my_contributions']);
  List<Map<String, dynamic>> get _cases => _asMaps(_dashboard['funeral_cases']);
  List<Map<String, dynamic>> get _membershipRequests =>
      _asMaps(_dashboard['membership_requests']);

  String get _societyName =>
      widget.space['society_name'] as String? ??
      widget.space['display_name'] as String? ??
      'Society';

  String get _roleName {
    final roles = _currentMember['office_roles'];
    if (roles is List && roles.isNotEmpty) {
      return roles.map((role) => _formatRole('$role')).join(', ');
    }
    return _formatRole(
      _currentMember['role_code'] as String? ??
          widget.space['role_code'] as String? ??
          'member',
    );
  }

  String _formatRole(String role) => role
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  List<Map<String, dynamic>> _asMaps(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList()
      : <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadProfile();
    _loadMemberView();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.api.getMyProfile(widget.sessionToken);
      if (mounted) setState(() => _profile = profile);
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProfileEditDialog(
        api: widget.api,
        sessionToken: widget.sessionToken,
        profile: _profile,
      ),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final dashboard = await widget.api.getSocietyDashboard(
        spaceId: _spaceId,
        sessionToken: widget.sessionToken,
      );
      if (mounted) setState(() => _dashboard = dashboard);
    } on RegistrationApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMemberView(String view) async {
    if (view == _memberView) return;
    setState(() {
      _memberView = view;
      _memberSearch = '';
    });
    await _loadMemberView();
  }

  Future<void> _loadMemberView() async {
    final request = ++_memberViewRequest;
    final view = _memberView;
    setState(() {
      _isLoadingMemberView = true;
      _memberViewError = null;
    });
    try {
      if (view == 'covered-lives') {
        final data = await widget.api.getMyCoveredLives(
          spaceId: _spaceId,
          sessionToken: widget.sessionToken,
        );
        if (mounted && request == _memberViewRequest) {
          setState(() => _myCoveredLifeData = data);
        }
      } else {
        final members = await widget.api.listActiveSocietyMembers(
          spaceId: _spaceId,
          sessionToken: widget.sessionToken,
        );
        if (mounted && request == _memberViewRequest) {
          setState(() => _societyMembers = members);
        }
      }
    } on RegistrationApiException catch (error) {
      if (mounted && request == _memberViewRequest) {
        setState(() => _memberViewError = error.message);
      }
    } finally {
      if (mounted && request == _memberViewRequest) {
        setState(() => _isLoadingMemberView = false);
      }
    }
  }

  String _money(dynamic amount) {
    final value = amount is num ? amount : num.tryParse('$amount') ?? 0;
    return 'R${value.toStringAsFixed(2)}';
  }

  String _periodLabel(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    return date == null
        ? 'Latest period'
        : MaterialLocalizations.of(context).formatMonthYear(date);
  }

  String _activityTitle(Map<String, dynamic> activity) {
    final eventCount = activity['event_count'] as int? ?? 1;
    return switch (activity['activity_type']) {
      'contributions_received' => '${_money(activity['amount'])} received',
      'funeral_cases_reported' =>
        '$eventCount funeral ${eventCount == 1 ? 'case' : 'cases'} reported',
      'funeral_cases_approved' =>
        '$eventCount funeral ${eventCount == 1 ? 'case' : 'cases'} approved',
      'member_created' => 'Member added',
      'member_updated' => 'Member details updated',
      'member_deactivated' => 'Member deactivated',
      'covered_life_added' => 'Covered life added',
      'covered_life_updated' => 'Covered life details updated',
      'covered_life_deactivated' => 'Covered life deactivated',
      _ => 'Society activity',
    };
  }

  String _activitySubtitle(Map<String, dynamic> activity) {
    final date = DateTime.tryParse('${activity['occurred_at'] ?? ''}');
    final dateLabel = date == null
        ? 'Recently'
        : MaterialLocalizations.of(context).formatMediumDate(date);
    if (activity['activity_type'] == 'contributions_received') {
      final eventCount = activity['event_count'] as int? ?? 1;
      return '$eventCount ${eventCount == 1 ? 'payment' : 'payments'} · $dateLabel';
    }
    return dateLabel;
  }

  Widget _pageHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _panel(
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) => Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: child,
  );

  Widget _metric(String label, String value, {String? detail}) => Container(
    constraints: const BoxConstraints(minHeight: 76),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(color: AppColors.muted, fontSize: 8),
          ),
        ],
      ],
    ),
  );

  Widget _statusLabel(String status) {
    final isPositive =
        status == 'active' || status == 'paid' || status == 'approved';
    final color = isPositive ? AppColors.forest : const Color(0xFF8A5412);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFEAF1EC) : const Color(0xFFFFF1D9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatRole(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showWorkspaceMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.api.logout(widget.sessionToken);
    } on RegistrationApiException {
      if (!mounted) return;
      _showWorkspaceMessage('Could not confirm sign-out with the server.');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(api: widget.api)),
      (_) => false,
    );
  }

  Future<void> _approveCase(String caseId) async {
    try {
      await widget.api.approveFuneralCase(
        spaceId: _spaceId,
        caseId: caseId,
        sessionToken: widget.sessionToken,
      );
      if (mounted) await _loadDashboard();
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _completeCasePayout(String caseId) async {
    try {
      await widget.api.completeFuneralCasePayout(
        spaceId: _spaceId,
        caseId: caseId,
        sessionToken: widget.sessionToken,
      );
      if (mounted) await _loadDashboard();
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _registerFuneralCase() async {
    final existingDetails = _asMap(_dashboard['existing_payout_details']);
    final registration = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _FuneralRegistrationDialog(
        existingBankDetails: existingDetails.isEmpty ? null : existingDetails,
      ),
    );
    if (registration == null || !mounted) return;
    try {
      await widget.api.registerFuneralCase(
        spaceId: _spaceId,
        sessionToken: widget.sessionToken,
        registration: registration,
      );
      if (!mounted) return;
      await _loadDashboard();
      await _loadMemberView();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Funeral registered'),
          content: const Text(
            'The funeral was successfully registered and is pending approval.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _approveMembership(String requestId) async {
    try {
      await widget.api.approveMembershipRequest(
        spaceId: _spaceId,
        requestId: requestId,
        sessionToken: widget.sessionToken,
      );
      if (mounted) await _loadDashboard();
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: AppColors.forest,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _societyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Together, with care',
                        style: TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _AccountMenuButton(
                key: const Key('society-account-button'),
                isSigningOut: _isSigningOut,
                avatarBytes: _decodeAvatar(_profile),
                onEditProfile: _editProfile,
                onSignOut: _signOut,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view_outlined, size: 13),
                    SizedBox(width: 6),
                    Text(
                      'Society Space',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.keyboard_arrow_down, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildHomeTab(),
                    _buildMembersTab(),
                    _buildContributionsTab(),
                    _buildFuneralCasesTab(),
                    _buildMoreTab(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildWorkspaceNavigation(),
    );
  }

  Widget _buildWorkspaceNavigation() {
    const tabs = [
      ('Home', 'society-tab-home', Icons.home_outlined, Icons.home),
      ('Members', 'society-tab-members', Icons.groups_outlined, Icons.groups),
      (
        'Contributions',
        'society-tab-contributions',
        Icons.payments_outlined,
        Icons.payments,
      ),
      (
        'Funeral cases',
        'society-tab-cases',
        Icons.assignment_outlined,
        Icons.assignment,
      ),
      ('More', 'society-tab-more', Icons.more_horiz, Icons.more_horiz),
    ];
    return NavigationBar(
      height: 68,
      backgroundColor: AppColors.white,
      indicatorColor: const Color(0xFFEAF1EC),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) => setState(() => _selectedTab = index),
      destinations: [
        for (final tab in tabs)
          NavigationDestination(
            key: Key(tab.$2),
            icon: Icon(tab.$3),
            selectedIcon: Icon(tab.$4),
            label: tab.$1,
          ),
      ],
    );
  }

  Future<void> _openMemberDetails(Map<String, dynamic> member) async {
    final memberId = member['member_id'] as String?;
    if (memberId == null) return;
    try {
      final details = await widget.api.getSocietyMember(
        spaceId: _spaceId,
        memberId: memberId,
        sessionToken: widget.sessionToken,
      );
      if (!mounted) return;
      final coveredLives = _asMaps(details['covered_lives']);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${details['given_name']} ${details['surname']}'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member number: ${details['member_number']}'),
                  Text('Joined: ${details['joined_at']}'),
                  Text('Status: ${_formatRole('${details['status']}')}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Covered lives',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (coveredLives.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No covered lives recorded.'),
                    ),
                  for (final life in coveredLives)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(life['display_name'] as String? ?? ''),
                      subtitle: Text(
                        '${_formatRole('${life['relationship_code']}')} · ${life['effective_from']}${life['effective_to'] == null ? '' : ' to ${life['effective_to']}'} · ${life['status']}',
                      ),
                      trailing: _canManageMembers && life['status'] == 'active'
                          ? Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Edit covered life',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _editCoveredLife(member, life);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Deactivate covered life',
                                  icon: const Icon(Icons.person_off_outlined),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _deactivateCoveredLife(member, life);
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (_canManageMembers) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _editMember(details);
                },
                child: const Text('Edit member'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _editCoveredLife(details, null);
                },
                child: const Text('Add covered life'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showMemberHistory(memberId);
                },
                child: const Text('Change history'),
              ),
              if (details['status'] == 'active')
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _deactivateMember(details);
                  },
                  child: const Text('Deactivate member'),
                ),
            ],
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  bool get _canManageMembers => _permissions['can_manage_members'] == true;

  Future<Map<String, Object?>?> _memberForm({Map<String, dynamic>? member}) {
    var number = member?['member_number'] as String? ?? '';
    var givenName = member?['given_name'] as String? ?? '';
    var surname = member?['surname'] as String? ?? '';
    var joinedAt =
        member?['joined_at'] as String? ??
        DateTime.now().toIso8601String().substring(0, 10);
    return showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(member == null ? 'Add member' : 'Edit member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('member-number-field'),
                initialValue: number,
                onChanged: (value) => number = value,
                decoration: const InputDecoration(labelText: 'Member number'),
              ),
              TextFormField(
                key: const Key('member-given-name-field'),
                initialValue: givenName,
                onChanged: (value) => givenName = value,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              TextFormField(
                key: const Key('member-surname-field'),
                initialValue: surname,
                onChanged: (value) => surname = value,
                decoration: const InputDecoration(labelText: 'Surname'),
              ),
              TextFormField(
                key: const Key('member-joined-date-field'),
                initialValue: joinedAt,
                onChanged: (value) => joinedAt = value,
                decoration: const InputDecoration(
                  labelText: 'Joined date (YYYY-MM-DD)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('save-society-member'),
            onPressed: () => Navigator.of(dialogContext).pop({
              'memberNumber': number.trim(),
              'givenName': givenName.trim(),
              'surname': surname.trim(),
              'joinedAt': joinedAt.trim(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMember([Map<String, dynamic>? member]) async {
    final changes = await _memberForm(member: member);
    if (changes == null) return;
    try {
      if (member == null) {
        await widget.api.createSocietyMember(
          spaceId: _spaceId,
          sessionToken: widget.sessionToken,
          member: changes,
        );
      } else {
        await widget.api.updateSocietyMember(
          spaceId: _spaceId,
          memberId: member['member_id'] as String,
          sessionToken: widget.sessionToken,
          changes: changes,
        );
      }
      if (mounted) {
        await _loadDashboard();
        await _loadMemberView();
      }
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<Map<String, Object?>?> _coveredLifeForm({
    Map<String, dynamic>? coveredLife,
  }) async {
    final personNumber = TextEditingController(
      text: '${coveredLife?['person_number'] ?? ''}',
    );
    final name = TextEditingController(
      text: coveredLife?['display_name'] as String? ?? '',
    );
    final identityNumber = TextEditingController(
      text: coveredLife?['identity_number'] as String? ?? '',
    );
    final effectiveFrom = TextEditingController(
      text:
          coveredLife?['effective_from'] as String? ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final effectiveTo = TextEditingController(
      text: coveredLife?['effective_to'] as String? ?? '',
    );
    var relationship =
        coveredLife?['relationship_code'] as String? ?? 'dependent';
    try {
      return await showDialog<Map<String, Object?>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              coveredLife == null ? 'Add covered life' : 'Edit covered life',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (coveredLife == null)
                    TextField(
                      controller: personNumber,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Person number',
                      ),
                    ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  TextField(
                    controller: identityNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID number (optional)',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: relationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'member', child: Text('Member')),
                      DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                      DropdownMenuItem(
                        value: 'dependent',
                        child: Text('Dependent'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(
                      () => relationship = value ?? 'dependent',
                    ),
                  ),
                  TextField(
                    controller: effectiveFrom,
                    decoration: const InputDecoration(
                      labelText: 'Effective from (YYYY-MM-DD)',
                    ),
                  ),
                  TextField(
                    controller: effectiveTo,
                    decoration: const InputDecoration(
                      labelText: 'Effective to (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('save-covered-life'),
                onPressed: () => Navigator.of(dialogContext).pop({
                  if (coveredLife == null)
                    'personNumber': int.tryParse(personNumber.text),
                  'displayName': name.text.trim(),
                  'identityNumber': identityNumber.text.trim().isEmpty
                      ? null
                      : identityNumber.text.trim(),
                  'relationshipCode': relationship,
                  'effectiveFrom': effectiveFrom.text.trim(),
                  'effectiveTo': effectiveTo.text.trim().isEmpty
                      ? null
                      : effectiveTo.text.trim(),
                }),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      personNumber.dispose();
      name.dispose();
      identityNumber.dispose();
      effectiveFrom.dispose();
      effectiveTo.dispose();
    }
  }

  Future<void> _editCoveredLife(
    Map<String, dynamic> member,
    Map<String, dynamic>? coveredLife,
  ) async {
    final values = await _coveredLifeForm(coveredLife: coveredLife);
    if (values == null) return;
    try {
      final memberId = member['member_id'] as String;
      if (coveredLife == null) {
        await widget.api.createCoveredLife(
          spaceId: _spaceId,
          memberId: memberId,
          sessionToken: widget.sessionToken,
          coveredLife: values,
        );
      } else {
        await widget.api.updateCoveredLife(
          spaceId: _spaceId,
          memberId: memberId,
          coveredLifeId: coveredLife['covered_life_id'] as String,
          sessionToken: widget.sessionToken,
          changes: values,
        );
      }
      if (mounted) {
        await _loadDashboard();
        await _loadMemberView();
      }
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _addOwnCoveredLife() async {
    final values = await _ownCoveredLifeForm();
    if (values == null) return;
    try {
      await widget.api.createMyCoveredLife(
        spaceId: _spaceId,
        sessionToken: widget.sessionToken,
        coveredLife: values,
      );
      if (!mounted) return;
      await _loadMemberView();
      if (mounted) _showWorkspaceMessage('Covered life added.');
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<Map<String, Object?>?> _ownCoveredLifeForm() =>
      showDialog<Map<String, Object?>>(
        context: context,
        builder: (_) => const _OwnCoveredLifeDialog(),
      );

  Future<void> _deactivateMember(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate member?'),
        content: const Text(
          'This also ends active covered lives, office assignments, and linked Space access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deactivateSocietyMember(
        spaceId: _spaceId,
        memberId: member['member_id'] as String,
        sessionToken: widget.sessionToken,
      );
      if (mounted) {
        await _loadDashboard();
        await _loadMemberView();
      }
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _deactivateCoveredLife(
    Map<String, dynamic> member,
    Map<String, dynamic> coveredLife,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate covered life?'),
        content: Text(
          'Remove ${coveredLife['display_name'] ?? 'this person'} from active cover?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deactivateCoveredLife(
        spaceId: _spaceId,
        memberId: member['member_id'] as String,
        coveredLifeId: coveredLife['covered_life_id'] as String,
        sessionToken: widget.sessionToken,
      );
      if (mounted) {
        await _loadDashboard();
        await _loadMemberView();
      }
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Future<void> _showMemberHistory(String memberId) async {
    try {
      final history = await widget.api.getSocietyMemberHistory(
        spaceId: _spaceId,
        memberId: memberId,
        sessionToken: widget.sessionToken,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Change history'),
          content: SizedBox(
            width: 360,
            child: history.isEmpty
                ? const Text('No changes recorded yet.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry in history)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${entry['action']}'.replaceAll('_', ' '),
                          ),
                          subtitle: Text(
                            '${entry['occurred_at']} · ${entry['actor_user_id']}',
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on RegistrationApiException catch (error) {
      if (mounted) _showWorkspaceMessage(error.message);
    }
  }

  Widget _buildHomeTab() {
    final pendingCases = _summary['pending_cases'] as int? ?? 0;
    final approvedCases = _summary['approved_cases'] as int? ?? 0;
    final arrearsCount = _summary['members_in_arrears'] as int? ?? 0;
    final preferredName = (_profile['preferred_name'] as String?)?.trim();
    final memberName = preferredName == null || preferredName.isEmpty
        ? _currentMember['given_name'] as String? ?? 'member'
        : preferredName;
    final now = DateTime.now();
    final totalDue = _toDouble(_summary['total_due']);
    final totalCollected = _toDouble(_summary['total_collected']);
    final contributionProgress = totalDue <= 0
        ? 0.0
        : (totalCollected / totalDue).clamp(0.0, 1.0);
    final contributionPercent = (contributionProgress * 100).round();
    return ListView(
      key: const Key('society-space-home'),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      children: [
        Text(
          _formattedHomeDate(now),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${societyGreetingFor(now)}, $memberName',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 34,
            height: 1.12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Here’s where your society stands today.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        const Text(
          'At a glance',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _panel(
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _homeMetric(
                      'Active members',
                      '${_summary['active_members'] ?? 0}',
                      '${_summary['covered_lives'] ?? 0} covered lives',
                    ),
                  ),
                  Container(width: 1, height: 74, color: AppColors.border),
                  Expanded(
                    child: _homeMetric(
                      'Open funeral cases',
                      '${pendingCases + approvedCases}',
                      '$pendingCases pending · $approvedCases approved',
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 13, 2, 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_periodLabel(_summary['period_start'] as String?)} contributions',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '$contributionPercent% collected',
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _money(_summary['total_collected']),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'of ${_money(_summary['total_due'])} due',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: contributionProgress,
                        minHeight: 4,
                        color: AppColors.forest,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$arrearsCount members in arrears',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('home-view-contributions'),
                          onPressed: () => setState(() => _selectedTab = 2),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View contributions →',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Needs attention',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            if (pendingCases + arrearsCount > 0)
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2B14B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${pendingCases + arrearsCount}',
                  style: const TextStyle(
                    color: Color(0xFF4A3511),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        if (pendingCases > 0)
          _homeAttentionItem(
            icon: Icons.assignment_outlined,
            title: '$pendingCases funeral cases awaiting review',
            detail: _permissions['can_view_cases'] == true
                ? 'Review pending cases in your officer queue.'
                : 'Track the cases you have reported and their status.',
            action: 'Open funeral cases →',
            onTap: () => setState(() => _selectedTab = 3),
          ),
        if (arrearsCount > 0)
          _homeAttentionItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Match $arrearsCount member contribution balances',
            detail: 'Outstanding Society contributions need follow-up.',
            action: 'View contributions →',
            onTap: () => setState(() => _selectedTab = 2),
          ),
        if (pendingCases == 0 && arrearsCount == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No items need attention right now.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (_recentActivity.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No recent activity has been recorded yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          )
        else
          ..._recentActivity.map(
            (activity) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2B14B),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  activity['activity_type'] == 'contributions_received'
                      ? Icons.payments_outlined
                      : activity['activity_type'].toString().startsWith(
                          'funeral_cases_',
                        )
                      ? Icons.assignment_outlined
                      : Icons.groups_outlined,
                  color: const Color(0xFF81530D),
                  size: 19,
                ),
              ),
              title: Text(
                _activityTitle(activity),
                style: const TextStyle(fontSize: 11),
              ),
              subtitle: Text(
                _activitySubtitle(activity),
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }

  Widget _homeMetric(String label, String value, String detail) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    ),
  );

  Widget _homeAttentionItem({
    required IconData icon,
    required String title,
    required String detail,
    required String? action,
    required VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE2B14B),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: const Color(0xFF81530D), size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
              if (action != null && onTap != null)
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  String _formattedHomeDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1].toUpperCase()}, ${date.day} ${months[date.month - 1].toUpperCase()} ${date.year}';
  }

  double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  Widget _buildMembersTab() {
    final query = _memberSearch.trim().toLowerCase();
    final visibleMembers = _societyMembers.where((member) {
      final name = '${member['given_name'] ?? ''} ${member['surname'] ?? ''}'
          .toLowerCase();
      final number = (member['member_number'] as String? ?? '').toLowerCase();
      return query.isEmpty || name.contains(query) || number.contains(query);
    }).toList();
    final coveredLives = _asMaps(_myCoveredLifeData['covered_lives']);
    final activeCoveredLives =
        _myCoveredLifeData['active_covered_life_count'] as int? ?? 0;
    final maxCoveredLives =
        _myCoveredLifeData['max_covered_lives_per_member'] as int? ?? 0;
    final showingCoveredLives = _memberView == 'covered-lives';
    return ListView(
      key: const Key('society-space-members'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _pageHeading('Members', 'Society membership and covered lives.'),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          key: const Key('member-view-filter'),
          segments: const [
            ButtonSegment(
              value: 'covered-lives',
              label: Text('Show covered lives'),
            ),
            ButtonSegment(
              value: 'society-members',
              label: Text('Show society members'),
            ),
          ],
          selected: {_memberView},
          onSelectionChanged: (selection) => _selectMemberView(selection.first),
          showSelectedIcon: false,
        ),
        if (_isLoadingMemberView)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_memberViewError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(_memberViewError!, textAlign: TextAlign.center),
                TextButton.icon(
                  onPressed: _loadMemberView,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (showingCoveredLives) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Active covered lives',
                  '$activeCoveredLives of $maxCoveredLives',
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const Key('add-own-covered-life'),
                tooltip: 'Add new covered life',
                onPressed: activeCoveredLives < maxCoveredLives
                    ? _addOwnCoveredLife
                    : null,
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your covered lives',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          if (coveredLives.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('No covered lives recorded yet.')),
            ),
          ...coveredLives.map((life) {
            final name = life['display_name'] as String? ?? '';
            final relationship = _formatRole(
              life['relationship_code'] as String? ?? 'dependent',
            );
            return _panel(
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFEAF1EC),
                    foregroundColor: AppColors.forest,
                    child: Icon(Icons.person_outline, size: 17),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          relationship,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statusLabel(life['status'] as String? ?? 'active'),
                      if (life['has_pending_funeral_case'] == true) ...[
                        const SizedBox(height: 4),
                        _statusLabel('funeral_pending'),
                      ],
                    ],
                  ),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(10),
            );
          }),
          if (activeCoveredLives >= maxCoveredLives)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Your Society’s covered-life limit has been reached.',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
        ] else ...[
          const SizedBox(height: 10),
          if (_canManageMembers)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('add-society-member'),
                onPressed: () => _editMember(),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add member'),
              ),
            ),
          if (_canManageMembers) const SizedBox(height: 10),
          TextField(
            key: const Key('society-member-search'),
            onChanged: (value) => setState(() => _memberSearch = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText:
                  'Search name${_canManageMembers ? ' or member number' : ''}',
              isDense: true,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing ${visibleMembers.length} of ${_societyMembers.length} active society members',
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
          const SizedBox(height: 5),
          ...visibleMembers.map((member) {
            final name =
                '${member['given_name'] ?? ''} ${member['surname'] ?? ''}'
                    .trim();
            final memberNumber = member['member_number'] as String? ?? '';
            final maskedMemberNumber = memberNumber.length <= 4
                ? '••••'
                : '•••• ${memberNumber.substring(memberNumber.length - 4)}';
            return _panel(
              InkWell(
                onTap: _canManageMembers
                    ? () => _openMemberDetails(member)
                    : null,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEAF1EC),
                      foregroundColor: AppColors.forest,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (memberNumber.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              maskedMemberNumber,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _statusLabel('active'),
                  ],
                ),
              ),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(10),
            );
          }),
          if (visibleMembers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('No active society members found.')),
            ),
        ],
      ],
    );
  }

  Widget _buildContributionsTab() {
    return ListView(
      key: const Key('society-space-contributions'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _pageHeading(
          'Contributions',
          _permissions['can_view_finances'] == true
              ? 'Society totals and your contribution history.'
              : 'Your contribution history.',
        ),
        const SizedBox(height: 10),
        if (_permissions['can_view_finances'] == true) ...[
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Society total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _periodLabel(_summary['period_start'] as String?),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_money(_summary['total_collected'])} of ${_money(_summary['total_due'])}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_money(_summary['outstanding'])} outstanding · ${_summary['members_in_arrears'] ?? 0} members in arrears',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monthly contribution: ${_money(_summary['monthly_contribution'])}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Your contribution history',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        if (_contributions.isEmpty)
          const Text(
            'No contribution entries are recorded for your membership yet.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          )
        else
          ..._contributions.map(
            (contribution) => _panel(
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.forest,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _periodLabel(contribution['period_start'] as String?),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_money(contribution['amount_paid'])} paid of ${_money(contribution['amount_due'])}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusLabel(contribution['status'] as String? ?? 'unpaid'),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(10),
            ),
          ),
      ],
    );
  }

  Widget _buildFuneralCasesTab() {
    final canApprove = _permissions['can_approve_funeral_cases'] == true;
    final canViewCases = _permissions['can_view_cases'] == true;
    final pendingCases = canViewCases
        ? _cases.where((record) => record['status'] == 'pending').toList()
        : <Map<String, dynamic>>[];
    final caseHistory = _cases
        .where((record) => record['status'] != 'pending')
        .toList();

    return ListView(
      key: const Key('society-space-cases'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _pageHeading(
          canApprove ? 'Funeral case decisions' : 'Funeral cases',
          canApprove
              ? 'Review cases awaiting your decision or register a funeral.'
              : 'Register a funeral and track the status of your cases.',
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('register-funeral-case'),
            onPressed: _registerFuneralCase,
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Register funeral'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
        if (canViewCases) ...[
          const SizedBox(height: 16),
          Text(
            canApprove ? 'Needs your decision' : 'Cases needing officer review',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          if (pendingCases.isEmpty)
            const Text(
              'No cases are waiting for a decision.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            )
          else
            ...pendingCases.map(
              (caseRecord) =>
                  _buildFuneralCaseCard(caseRecord, canApprove: canApprove),
            ),
          const SizedBox(height: 14),
          const Text(
            'Case history',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          if (caseHistory.isEmpty)
            const Text(
              'No decided cases are available yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            )
          else
            ...caseHistory.map(
              (caseRecord) => _buildFuneralCaseCard(caseRecord),
            ),
        ] else ...[
          const SizedBox(height: 16),
          if (_cases.isEmpty)
            const Text(
              'You have not registered any funeral cases.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            )
          else
            ..._cases.map((caseRecord) => _buildFuneralCaseCard(caseRecord)),
        ],
      ],
    );
  }

  Widget _buildFuneralCaseCard(
    Map<String, dynamic> caseRecord, {
    bool canApprove = false,
  }) {
    final caseId = caseRecord['funeral_case_id'] as String? ?? '';
    final status = caseRecord['status'] as String? ?? 'pending';
    final payoutStatus = caseRecord['payout_status'] as String?;
    final displayStatus = switch (status) {
      'pending' => 'pending_approval',
      'approved' => payoutStatus == 'completed' ? 'completed' : 'in_progress',
      _ => status,
    };
    final memberName =
        '${caseRecord['given_name'] ?? ''} ${caseRecord['surname'] ?? ''}'
            .trim();
    final deceasedName =
        '${caseRecord['deceased_given_name'] ?? ''} ${caseRecord['deceased_surname'] ?? ''}'
            .trim();
    final dateOfDeath = DateTime.tryParse(
      '${caseRecord['date_of_death'] ?? ''}',
    );
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  caseRecord['case_reference'] as String? ?? 'Funeral case',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusLabel(displayStatus),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Member ${caseRecord['member_number'] ?? ''} · $memberName',
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
          if (deceasedName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Deceased: $deceasedName',
              style: const TextStyle(fontSize: 10),
            ),
          ],
          if (dateOfDeath != null)
            Text(
              'Date of death: ${MaterialLocalizations.of(context).formatMediumDate(dateOfDeath)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          const SizedBox(height: 6),
          if ((caseRecord['summary'] as String? ?? '').isNotEmpty)
            Text(
              caseRecord['summary'] as String,
              style: const TextStyle(fontSize: 10, height: 1.4),
            ),
          if (status == 'pending' && canApprove) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: Key('approve-case-$caseId'),
                onPressed: () => _approveCase(caseId),
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Approve case'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
          if (status == 'approved' &&
              payoutStatus == 'in_progress' &&
              _permissions['can_view_finances'] == true) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('complete-payout-$caseId'),
                onPressed: () => _completeCasePayout(caseId),
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: const Text('Mark payout complete'),
              ),
            ),
          ],
        ],
      ),
      margin: const EdgeInsets.only(bottom: 8),
    );
  }

  Widget _buildMoreTab() {
    final joinedAt = widget.space['joined_at'] as String?;
    final joinedDate = joinedAt == null ? null : DateTime.tryParse(joinedAt);
    final joinedLabel = joinedDate == null
        ? 'Not available'
        : MaterialLocalizations.of(context).formatMediumDate(joinedDate);
    return ListView(
      key: const Key('society-space-more'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _pageHeading('More', 'Your membership and society information.'),
        const SizedBox(height: 10),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your membership',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              _SocietyInfoRow(
                icon: Icons.badge_outlined,
                label: 'Member number',
                value:
                    _currentMember['member_number'] as String? ??
                    widget.space['member_number'] as String? ??
                    'Not available',
              ),
              _SocietyInfoRow(
                icon: Icons.account_circle_outlined,
                label: 'Your role',
                value: _roleName,
              ),
              _SocietyInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Member since',
                value: joinedLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Approved fees',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              _SocietyInfoRow(
                icon: Icons.payments_outlined,
                label: 'Monthly contribution',
                value: _money(_summary['monthly_contribution']),
              ),
              _SocietyInfoRow(
                icon: Icons.person_add_alt_outlined,
                label: 'Joining fee',
                value: _summary['joining_fee'] == null
                    ? 'Not configured'
                    : _money(_summary['joining_fee']),
              ),
            ],
          ),
        ),
        if (_permissions['can_approve_memberships'] == true) ...[
          const SizedBox(height: 16),
          _buildMembershipApprovals(),
        ],
      ],
    );
  }

  Widget _buildMembershipApprovals() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Membership applications',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      if (_membershipRequests.isEmpty)
        const Text(
          'No applications are waiting for your review.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        )
      else
        ..._membershipRequests.map((request) {
          final requestId = request['membership_request_id'] as String? ?? '';
          return _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request['given_name'] ?? ''} ${request['surname'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Member number ${request['requested_member_number']}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
                const SizedBox(height: 7),
                FilledButton(
                  key: Key('approve-membership-$requestId'),
                  onPressed: () => _approveMembership(requestId),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Approve membership'),
                ),
              ],
            ),
            margin: const EdgeInsets.only(bottom: 7),
          );
        }),
    ],
  );
}

class _SocietyInfoRow extends StatelessWidget {
  const _SocietyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: AppColors.forest, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnCoveredLifeDialog extends StatefulWidget {
  const _OwnCoveredLifeDialog();

  @override
  State<_OwnCoveredLifeDialog> createState() => _OwnCoveredLifeDialogState();
}

class _OwnCoveredLifeDialogState extends State<_OwnCoveredLifeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _identityNumberController = TextEditingController();
  String _relationship = 'dependent';

  @override
  void dispose() {
    _givenNameController.dispose();
    _surnameController.dispose();
    _identityNumberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final displayName =
        '${_givenNameController.text.trim()} ${_surnameController.text.trim()}';
    Navigator.of(context).pop<Map<String, Object?>>({
      'displayName': displayName,
      'identityNumber': _identityNumberController.text.trim().isEmpty
          ? null
          : _identityNumberController.text.trim(),
      'relationshipCode': _relationship,
      'effectiveFrom': DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add new covered life'),
    content: SizedBox(
      width: 380,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('own-covered-life-given-name'),
                controller: _givenNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a first name.'
                    : null,
              ),
              TextFormField(
                key: const Key('own-covered-life-surname'),
                controller: _surnameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Surname'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a surname.'
                    : null,
              ),
              TextFormField(
                key: const Key('own-covered-life-id-number'),
                controller: _identityNumberController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'ID number (optional)',
                ),
                validator: (value) {
                  final id = value?.trim() ?? '';
                  if (id.isEmpty) return null;
                  if (id.length < 6 ||
                      id.length > 32 ||
                      !RegExp(r'^[a-zA-Z0-9 -]+$').hasMatch(id)) {
                    return 'Enter a valid ID number.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                key: const Key('own-covered-life-relationship'),
                initialValue: _relationship,
                decoration: const InputDecoration(labelText: 'Relationship'),
                items: const [
                  DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                  DropdownMenuItem(
                    value: 'dependent',
                    child: Text('Dependent'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _relationship = value ?? 'dependent'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('save-own-covered-life'),
        onPressed: _submit,
        child: const Text('Add covered life'),
      ),
    ],
  );
}

class _FuneralRegistrationDialog extends StatefulWidget {
  const _FuneralRegistrationDialog({required this.existingBankDetails});

  final Map<String, dynamic>? existingBankDetails;

  @override
  State<_FuneralRegistrationDialog> createState() =>
      _FuneralRegistrationDialogState();
}

class _FuneralRegistrationDialogState
    extends State<_FuneralRegistrationDialog> {
  static const _bankNames = [
    'Absa',
    'African Bank',
    'Bank Zero',
    'Bidvest Bank',
    'Capitec Bank',
    'Discovery Bank',
    'FNB',
    'Grindrod Bank',
    'Investec',
    'Nedbank',
    'Standard Bank',
    'TymeBank',
    'Ubank',
  ];

  final _formKey = GlobalKey<FormState>();
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _dateOfDeathController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  String? _bankName;
  late bool _useExistingBankDetails;

  bool get _hasExistingBankDetails =>
      widget.existingBankDetails?['bank_name'] is String &&
      widget.existingBankDetails?['account_name'] is String &&
      widget.existingBankDetails?['account_number'] is String;

  @override
  void initState() {
    super.initState();
    _useExistingBankDetails = _hasExistingBankDetails;
    final existingBankName = widget.existingBankDetails?['bank_name'];
    if (_bankNames.contains(existingBankName)) {
      _bankName = existingBankName as String;
    }
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _surnameController.dispose();
    _idNumberController.dispose();
    _dateOfDeathController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  String? _validateIdentity(String? value) {
    final hasNames =
        _givenNameController.text.trim().isNotEmpty &&
        _surnameController.text.trim().isNotEmpty;
    if (!hasNames && (value == null || value.trim().isEmpty)) {
      return 'Enter the name and surname or an ID number.';
    }
    return null;
  }

  String? _validateDate(String? value) {
    final date = value == null ? null : DateTime.tryParse(value.trim());
    if (date == null) return 'Enter the date as YYYY-MM-DD.';
    final today = DateTime.now();
    if (date.isAfter(DateTime(today.year, today.month, today.day))) {
      return 'The date of death cannot be in the future.';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop<Map<String, Object?>>({
      'givenName': _givenNameController.text.trim(),
      'surname': _surnameController.text.trim(),
      'deceasedIdNumber': _idNumberController.text.trim().isEmpty
          ? null
          : _idNumberController.text.trim(),
      'dateOfDeath': _dateOfDeathController.text.trim(),
      'useExistingBankDetails': _useExistingBankDetails,
      if (!_useExistingBankDetails) ...{
        'bankName': _bankName,
        'accountName': _accountNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
      },
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Register funeral'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('deceased-given-name-field'),
                controller: _givenNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              TextFormField(
                key: const Key('deceased-surname-field'),
                controller: _surnameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Surname'),
              ),
              TextFormField(
                key: const Key('deceased-id-number-field'),
                controller: _idNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID number (or enter name and surname)',
                ),
                validator: _validateIdentity,
              ),
              TextFormField(
                key: const Key('date-of-death-field'),
                controller: _dateOfDeathController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Date of death (YYYY-MM-DD)',
                ),
                validator: _validateDate,
              ),
              const SizedBox(height: 12),
              const Text(
                'Payout bank details',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              RadioGroup<bool>(
                groupValue: _useExistingBankDetails,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _useExistingBankDetails = value);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioListTile<bool>(
                      key: const Key('use-existing-bank-details'),
                      value: true,
                      enabled: _hasExistingBankDetails,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Yes, use existing bank details'),
                    ),
                    if (_hasExistingBankDetails && _useExistingBankDetails)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1EC),
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.existingBankDetails!['bank_name']} · '
                          '${widget.existingBankDetails!['account_name']}\n'
                          'Account ${widget.existingBankDetails!['account_number']}',
                          style: const TextStyle(fontSize: 11, height: 1.5),
                        ),
                      ),
                    if (!_hasExistingBankDetails)
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          'No existing bank details are on file. Enter new details below.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    RadioListTile<bool>(
                      key: const Key('enter-new-bank-details'),
                      value: false,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('No, enter different bank details'),
                    ),
                  ],
                ),
              ),
              if (!_useExistingBankDetails) ...[
                DropdownButtonFormField<String>(
                  key: const Key('payout-bank-field'),
                  initialValue: _bankName,
                  decoration: const InputDecoration(labelText: 'Bank name'),
                  items: _bankNames
                      .map(
                        (bank) =>
                            DropdownMenuItem(value: bank, child: Text(bank)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _bankName = value),
                  validator: (value) => value == null ? 'Select a bank.' : null,
                ),
                TextFormField(
                  key: const Key('payout-account-name-field'),
                  controller: _accountNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Account name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the account name.'
                      : null,
                ),
                TextFormField(
                  key: const Key('payout-account-number-field'),
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account number',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the account number.'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('submit-funeral-case'),
        onPressed: _submit,
        child: const Text('Submit'),
      ),
    ],
  );
}

class SocietyDirectoryScreen extends StatelessWidget {
  const SocietyDirectoryScreen({
    super.key,
    required this.spaces,
    required this.isLoading,
    required this.onRetry,
    this.loadError,
  });

  final List<Map<String, dynamic>> spaces;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text('Explore societies'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Societies',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Browse public profiles. Access to society information requires approval.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (loadError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loadError!,
                  style: const TextStyle(color: AppColors.muted),
                ),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            )
          else if (spaces.isEmpty)
            const Text(
              'No societies are listed yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            )
          else
            ...spaces.map((space) => _SocietyDirectoryCard(space: space)),
        ],
      ),
    );
  }
}

class _SocietyDirectoryCard extends StatelessWidget {
  const _SocietyDirectoryCard({required this.space});

  final Map<String, dynamic> space;

  @override
  Widget build(BuildContext context) {
    final spaceId = space['space_id'] as String? ?? '';
    final displayName = space['display_name'] as String? ?? 'Society Space';
    final description =
        space['public_description'] as String? ??
        'View public information about this Society Space.';

    return Container(
      key: Key('society-directory-card-$spaceId'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SocietyMonogramLogo(
                key: Key('society-logo-$spaceId'),
                name: displayName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Society Space · Public profile',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: Key('request-society-access-$spaceId'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(displayName),
                  content: const Text(
                    'Access requests are not connected yet. Public discovery does not grant access to members, covered lives, fees, or committee records.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Request access'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocietyMonogramLogo extends StatelessWidget {
  const _SocietyMonogramLogo({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(3)
        .map((word) => word[0].toUpperCase())
        .join();

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Uint8List? _decodeAvatar(Map<String, dynamic> profile) {
  final encoded = profile['avatar_base64'];
  if (encoded is! String || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } on FormatException {
    return null;
  }
}

class _SpacesBrandHeader extends StatelessWidget {
  const _SpacesBrandHeader({
    required this.isSigningOut,
    required this.avatarBytes,
    required this.onEditProfile,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final Uint8List? avatarBytes;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const SizedBox(width: 34, height: 28, child: _EverBondMark()),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EverBond',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Together, with care',
                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          _AccountMenuButton(
            key: const Key('sign-out-button'),
            isSigningOut: isSigningOut,
            avatarBytes: avatarBytes,
            onEditProfile: onEditProfile,
            onSignOut: onSignOut,
          ),
        ],
      ),
    ),
  );
}

class _AccountMenuButton extends StatelessWidget {
  const _AccountMenuButton({
    super.key,
    required this.isSigningOut,
    required this.avatarBytes,
    required this.onEditProfile,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final Uint8List? avatarBytes;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Account options',
    onSelected: (value) {
      if (value == 'edit-profile') onEditProfile();
      if (value == 'sign-out') onSignOut();
    },
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'edit-profile',
        child: ListTile(
          dense: true,
          leading: Icon(Icons.person_outline),
          title: Text('Edit profile'),
        ),
      ),
      PopupMenuItem(
        value: 'sign-out',
        child: ListTile(
          dense: true,
          leading: Icon(Icons.logout),
          title: Text('Sign out'),
        ),
      ),
    ],
    child: SizedBox.square(
      dimension: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: ClipOval(
          child: Center(
            child: isSigningOut
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : avatarBytes == null
                ? const Icon(
                    Icons.person_outline,
                    size: 17,
                    color: AppColors.forest,
                  )
                : Image.memory(
                    avatarBytes!,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_outline,
                      size: 17,
                      color: AppColors.forest,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({
    required this.api,
    required this.sessionToken,
    required this.profile,
  });

  final RegistrationApi api;
  final String sessionToken;
  final Map<String, dynamic> profile;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _preferredNameController;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMimeType;
  bool _clearAvatar = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _preferredNameController = TextEditingController(
      text:
          widget.profile['preferred_name'] as String? ??
          widget.profile['given_name'] as String? ??
          '',
    );
  }

  @override
  void dispose() {
    _preferredNameController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Profile images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (file == null || !mounted) return;
    final extension = file.name.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => null,
    };
    if (mimeType == null) {
      setState(() => _errorMessage = 'Choose a PNG, JPEG, or WebP image.');
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 512 * 1024) {
      setState(
        () => _errorMessage = 'Profile images must be 512 KB or smaller.',
      );
      return;
    }
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageMimeType = mimeType;
      _clearAvatar = false;
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    final preferredName = _preferredNameController.text.trim();
    if (preferredName.isEmpty) {
      setState(() => _errorMessage = 'Enter a preferred name.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final changes = <String, Object?>{'preferredName': preferredName};
    if (_selectedImageBytes != null) {
      changes['avatarBase64'] = base64Encode(_selectedImageBytes!);
      changes['avatarMimeType'] = _selectedImageMimeType;
    } else if (_clearAvatar) {
      changes['clearAvatar'] = true;
    }
    try {
      final profile = await widget.api.updateMyProfile(
        sessionToken: widget.sessionToken,
        changes: changes,
      );
      if (mounted) Navigator.of(context).pop(profile);
    } on RegistrationApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBytes =
        _selectedImageBytes ??
        (_clearAvatar ? null : _decodeAvatar(widget.profile));
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFEAF1EC),
                foregroundColor: AppColors.forest,
                backgroundImage: avatarBytes == null
                    ? null
                    : MemoryImage(avatarBytes),
                child: avatarBytes == null
                    ? const Icon(Icons.person_outline, size: 30)
                    : null,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('choose-profile-image'),
                onPressed: _isSaving ? null : _chooseImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choose profile image'),
              ),
              if (avatarBytes != null)
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                          _selectedImageBytes = null;
                          _selectedImageMimeType = null;
                          _clearAvatar = true;
                        }),
                  child: const Text('Remove image'),
                ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('preferred-name-field'),
                controller: _preferredNameController,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Preferred name',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-profile-button'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _SpacesNavigation extends StatelessWidget {
  const _SpacesNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 35,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        _SpacesNavigationTab(
          label: 'Spaces',
          index: 0,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
        _SpacesNavigationTab(
          label: 'Invitations',
          index: 1,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
        _SpacesNavigationTab(
          label: 'Help',
          index: 2,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      ],
    ),
  );
}

class _SpacesNavigationTab extends StatelessWidget {
  const _SpacesNavigationTab({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return InkWell(
      key: Key('navigation-${label.toLowerCase()}'),
      onTap: () => onSelected(index),
      child: SizedBox(
        width: label == 'Invitations' ? 82 : 66,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.forest : AppColors.muted,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              height: 2,
              color: isSelected ? AppColors.forest : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.actionKey,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.fromLTRB(9, 9, 9, 0),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, size: 15, color: AppColors.forest),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: AppColors.border),
        SizedBox(
          height: 34,
          child: FilledButton(
            key: actionKey,
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(actionLabel)),
                const Icon(Icons.arrow_forward, size: 13),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _HelpNote extends StatelessWidget {
  const _HelpNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.forest, size: 19),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SpaceOffering {
  const _SpaceOffering(this.icon, this.description);

  final IconData icon;
  final String description;
}

_SpaceOffering _offeringFor(
  String code,
  String fallbackTitle,
) => switch (code) {
  'society' => const _SpaceOffering(
    Icons.groups_outlined,
    'Manage membership, covered lives, contributions and society approvals.',
  ),
  'parlour' => const _SpaceOffering(
    Icons.home_work_outlined,
    'Coordinate funeral arrangements, service schedules and day-to-day operations.',
  ),
  'family' => const _SpaceOffering(
    Icons.family_restroom,
    'Keep family arrangements, important documents and updates together.',
  ),
  'supplier' => const _SpaceOffering(
    Icons.local_shipping_outlined,
    'Coordinate service requests, quotations and deliveries.',
  ),
  _ => _SpaceOffering(Icons.grid_view_outlined, fallbackTitle),
};

class _SpaceTypesError extends StatelessWidget {
  const _SpaceTypesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      TextButton.icon(
        key: const Key('retry-space-types'),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    ],
  );
}

InputDecoration _inputDecoration({
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AppColors.muted,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFB42318)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}

class _EverBondBrand extends StatelessWidget {
  const _EverBondBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 88, height: 66, child: _EverBondMark()),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'EverBond',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 29,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Together, with care',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EverBondMark extends StatelessWidget {
  const _EverBondMark();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: const CustomPaint(
        painter: _EverBondMarkPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _EverBondMarkPainter extends CustomPainter {
  const _EverBondMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(AppColors.forest, BlendMode.src);

    final linePaint = Paint()
      ..color = const Color(0xFF789487).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final centerY = size.height / 2;
    final endX = size.width - 3;
    canvas.drawLine(
      Offset(size.width * 0.47, centerY),
      Offset(endX, centerY),
      linePaint,
    );

    for (var index = 0; index < 6; index++) {
      final startY = 4.0 + index * (size.height - 8) / 5;
      final path = Path()
        ..moveTo(0, startY)
        ..cubicTo(
          size.width * 0.19,
          startY,
          size.width * 0.25,
          centerY,
          size.width * 0.5,
          centerY,
        );
      canvas.drawPath(path, linePaint);
    }

    final hubPaint = Paint()
      ..color = const Color(0xFF789487).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;
    for (var index = 0; index < 5; index++) {
      final startY = 9.0 + index * (size.height - 18) / 4;
      final path = Path()
        ..moveTo(0, startY)
        ..cubicTo(
          size.width * 0.23,
          startY,
          size.width * 0.27,
          centerY,
          size.width * 0.48,
          centerY,
        );
      canvas.drawPath(path, hubPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'or continue with',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.muted, fontSize: 13),
        ),
      ),
      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
    ],
  );
}

class _SocialSignInButton extends StatelessWidget {
  const _SocialSignInButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: Center(
      child: Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontFamily: 'Arial',
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    ),
  );
}

class _FacebookMark extends StatelessWidget {
  const _FacebookMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 21,
    height: 21,
    decoration: const BoxDecoration(
      color: Color(0xFF1877F2),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.bottomCenter,
    child: const Text(
      'f',
      style: TextStyle(
        color: AppColors.white,
        fontFamily: 'Arial',
        fontWeight: FontWeight.w700,
        fontSize: 19,
        height: 1.05,
      ),
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline,
          size: 15,
          color: AppColors.muted,
          semanticLabel: 'Locked',
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            "Your society's information, kept private.",
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

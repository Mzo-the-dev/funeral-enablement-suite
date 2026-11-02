import 'package:flutter/material.dart';

import 'access_flow.dart';
import 'registration_api.dart';

void main() {
  runApp(const FuneralSpacesApp());
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

  @override
  void initState() {
    super.initState();
    _loadSpaceTypes();
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
              onPressed: () => _showActiveSpaceInfo(displayName),
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

  void _showActiveSpaceInfo(String displayName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(displayName),
        content: const Text(
          'Your membership is active. The Society workspace content is not available in this preview yet.',
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

class _SpacesBrandHeader extends StatelessWidget {
  const _SpacesBrandHeader({
    required this.isSigningOut,
    required this.onSignOut,
  });

  final bool isSigningOut;
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
          PopupMenuButton<String>(
            key: const Key('sign-out-button'),
            tooltip: 'Account options',
            onSelected: (value) {
              if (value == 'sign-out') onSignOut();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
            ],
            child: SizedBox.square(
              dimension: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: isSigningOut
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.person_outline,
                          size: 17,
                          color: AppColors.forest,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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

import 'package:flutter/material.dart';

import 'main.dart' show AppColors;
import 'registration_api.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.api = const RegistrationApi()});

  final RegistrationApi api;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _preferredName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _spaceQuestionOne = TextEditingController();
  final _spaceQuestionTwo = TextEditingController();

  String? _space;
  String _verificationChannel = 'email';
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _location.dispose();
    _address.dispose();
    _preferredName.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _spaceQuestionOne.dispose();
    _spaceQuestionTwo.dispose();
    super.dispose();
  }

  List<String> get _spaceQuestions => switch (_space) {
    'Society Space' => [
      'Society name or invitation code',
      'Your role in the society',
    ],
    'Parlour Space' => [
      'Funeral parlour or business name',
      'Services you provide',
    ],
    'Family Space' => [
      'Family or society reference',
      'Your relationship to the family',
    ],
    'Supplier Space' => ['Business name', 'Products or services you provide'],
    _ => [],
  };

  String? get _spaceCode => switch (_space) {
    'Society Space' => 'society',
    'Parlour Space' => 'parlour',
    'Family Space' => 'family',
    'Supplier Space' => 'supplier',
    _ => null,
  };

  List<String> get _spaceQuestionKeys => switch (_spaceCode) {
    'society' => ['society_reference', 'society_role'],
    'parlour' => ['parlour_name', 'parlour_services'],
    'family' => ['family_reference', 'family_relationship'],
    'supplier' => ['supplier_business_name', 'supplier_services'],
    _ => [],
  };

  Future<void> _continueToVerification() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final destination = _verificationChannel == 'email'
        ? _email.text.trim()
        : _phone.text.trim();
    setState(() => _isSubmitting = true);
    try {
      final result = await widget.api.register({
        'username': _username.text.trim(),
        'givenName': _name.text.trim(),
        'surname': _surname.text.trim(),
        'preferredName': _preferredName.text.trim(),
        'location': _location.text.trim(),
        'address': _address.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'spaceCode': _spaceCode!,
        'verificationChannel': _verificationChannel,
        'answers': {
          for (var index = 0; index < _spaceQuestionKeys.length; index++)
            _spaceQuestionKeys[index]: index == 0
                ? _spaceQuestionOne.text.trim()
                : _spaceQuestionTwo.text.trim(),
        },
      });
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationOtpScreen(
            api: widget.api,
            registrationId: result['registrationId'] as String,
            destination: destination,
            channel: _verificationChannel,
            developmentOtp: result['otpForDevelopment'] as String?,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text(
                'Sign up',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account, then verify your email address or cell phone.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              _textField(
                key: const Key('registration-name'),
                controller: _name,
                label: 'Name',
                textCapitalization: TextCapitalization.words,
                validator: (value) => _required(value, 'Enter your name'),
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-surname'),
                controller: _surname,
                label: 'Surname',
                textCapitalization: TextCapitalization.words,
                validator: (value) => _required(value, 'Enter your surname'),
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-location'),
                controller: _location,
                label: 'Location (city or town)',
                textCapitalization: TextCapitalization.words,
                validator: (value) => _required(value, 'Enter your location'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const Key('registration-space'),
                initialValue: _space,
                decoration: _decoration('Select Space'),
                items: const [
                  DropdownMenuItem(
                    value: 'Society Space',
                    child: Text('Society Space'),
                  ),
                  DropdownMenuItem(
                    value: 'Parlour Space',
                    child: Text('Parlour Space'),
                  ),
                  DropdownMenuItem(
                    value: 'Family Space',
                    child: Text('Family Space'),
                  ),
                  DropdownMenuItem(
                    value: 'Supplier Space',
                    child: Text('Supplier Space'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _space = value;
                  _spaceQuestionOne.clear();
                  _spaceQuestionTwo.clear();
                }),
                validator: (value) => value == null ? 'Select a Space' : null,
              ),
              for (var index = 0; index < _spaceQuestions.length; index++) ...[
                const SizedBox(height: 14),
                _textField(
                  key: Key('registration-space-question-$index'),
                  controller: index == 0
                      ? _spaceQuestionOne
                      : _spaceQuestionTwo,
                  label: _spaceQuestions[index],
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) =>
                      _required(value, 'Answer: ${_spaceQuestions[index]}'),
                ),
              ],
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-username'),
                controller: _username,
                label: 'Username',
                validator: (value) {
                  final username = value?.trim() ?? '';
                  if (username.length < 3) return 'Use at least 3 characters';
                  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
                    return 'Use letters, numbers, dots, underscores, or hyphens';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-email'),
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Enter your email address';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-phone'),
                controller: _phone,
                label: 'Cell phone',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  return phone.length < 9
                      ? 'Enter a valid cell phone number'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-address'),
                controller: _address,
                label: 'Address',
                textCapitalization: TextCapitalization.words,
                validator: (value) => _required(value, 'Enter your address'),
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-preferred-name'),
                controller: _preferredName,
                label: 'Preferred name',
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    _required(value, 'Enter your preferred name'),
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-password'),
                controller: _password,
                label: 'Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Create a password';
                  }
                  if (value.length < 8) return 'Use at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _textField(
                key: const Key('registration-confirm-password'),
                controller: _confirmPassword,
                label: 'Confirm password',
                obscureText: _obscureConfirmation,
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmation
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 22),
              const Text(
                'Choose where to receive your one-time verification code after your account has been successfully created.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                key: const Key('registration-verification-channel'),
                segments: const [
                  ButtonSegment(value: 'email', label: Text('Email')),
                  ButtonSegment(value: 'sms', label: Text('Cell phone')),
                ],
                selected: {_verificationChannel},
                onSelectionChanged: (selection) =>
                    setState(() => _verificationChannel = selection.first),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: FilledButton(
                  key: const Key('registration-continue'),
                  onPressed: _isSubmitting ? null : _continueToVerification,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ),
              const SizedBox(height: 14),
              const _RegistrationPreviewNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({
    required this.api,
    required this.registrationId,
    required this.destination,
    required this.channel,
    this.developmentOtp,
    super.key,
  });

  final RegistrationApi api;
  final String registrationId;
  final String destination;
  final String channel;
  final String? developmentOtp;

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final _code = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isVerifying = true);
    try {
      await widget.api.verify(
        registrationId: widget.registrationId,
        code: _code.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Account verified. You can now log in.')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.channel == 'email' ? 'email' : 'cell phone';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your account'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: AppColors.forest,
            ),
            const SizedBox(height: 20),
            Text(
              'Confirm your $method',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'A one-time code was sent to ${_maskDestination(widget.destination, widget.channel)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('registration-otp'),
              controller: _code,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              decoration: _decoration('6-digit verification code'),
            ),
            if (widget.developmentOtp != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'Development code: ${widget.developmentOtp}',
                key: const Key('development-otp-code'),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: FilledButton(
                key: const Key('registration-verify'),
                onPressed: _isVerifying || _code.text.length != 6
                    ? null
                    : _verify,
                child: _isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify account'),
              ),
            ),
            const SizedBox(height: 12),
            const _RegistrationPreviewNotice(),
            const SizedBox(height: 22),
            const Text(
              'Local development uses a test code only. No real email or SMS is sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _textField({
  required Key key,
  required TextEditingController controller,
  required String label,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
  bool obscureText = false,
  Widget? suffixIcon,
}) {
  return TextFormField(
    key: key,
    controller: controller,
    decoration: _decoration(label, suffixIcon: suffixIcon),
    validator: validator,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    obscureText: obscureText,
    autofillHints: label == 'Email' ? const [AutofillHints.email] : null,
  );
}

String? _required(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;

InputDecoration _decoration(String label, {Widget? suffixIcon}) =>
    InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.white,
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
    );

String _maskDestination(String destination, String channel) {
  if (channel == 'email') {
    final parts = destination.split('@');
    if (parts.length != 2) return 'your email address';
    final first = parts.first.isEmpty ? '' : parts.first[0];
    return '$first•••@${parts.last}';
  }
  final digits = destination.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return 'your cell phone';
  return '${digits.substring(0, 3)}•••${digits.substring(digits.length - 2)}';
}

class _RegistrationPreviewNotice extends StatelessWidget {
  const _RegistrationPreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('registration-preview-notice'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3D8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'Development only: registration uses your local API and a test code. No real email or SMS is sent.',
      style: TextStyle(color: AppColors.ink, height: 1.4, fontSize: 13),
    ),
  );
}

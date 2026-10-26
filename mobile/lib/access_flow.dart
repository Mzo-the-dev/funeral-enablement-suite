import 'package:flutter/material.dart';

import 'main.dart' show AppColors;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

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

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _location.dispose();
    _address.dispose();
    _preferredName.dispose();
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

  void _continueToVerification() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final destination = _verificationChannel == 'email'
        ? _email.text.trim()
        : _phone.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationOtpScreen(
          destination: destination,
          channel: _verificationChannel,
        ),
      ),
    );
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
                  onPressed: _continueToVerification,
                  child: const Text('Create account'),
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

class RegistrationOtpScreen extends StatelessWidget {
  const RegistrationOtpScreen({
    required this.destination,
    required this.channel,
    super.key,
  });

  final String destination;
  final String channel;

  @override
  Widget build(BuildContext context) {
    final method = channel == 'email' ? 'email' : 'cell phone';
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
              'After registration succeeds, a one-time code will be sent to ${_maskDestination(destination, channel)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('registration-otp'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: _decoration('6-digit verification code'),
            ),
            const SizedBox(height: 12),
            const _RegistrationPreviewNotice(),
            const SizedBox(height: 22),
            const Text(
              'Account creation and OTP delivery are not connected to a server yet. This preview does not create an account or send a code.',
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
      'Preview only: the registration form is not connected to account creation or OTP delivery yet.',
      style: TextStyle(color: AppColors.ink, height: 1.4, fontSize: 13),
    ),
  );
}

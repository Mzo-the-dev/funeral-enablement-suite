import 'package:flutter/material.dart';

import 'access_flow.dart';

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
  const FuneralSpacesApp({super.key});

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
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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

  void _submitLogin() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      _showNotConnectedMessage('Sign-in');
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
                              onPressed: _submitLogin,
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
                              child: const Text('Log in'),
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

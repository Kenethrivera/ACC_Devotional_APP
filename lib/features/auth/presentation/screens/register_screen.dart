import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/otp_code_input.dart';

class RegisterScreen extends StatefulWidget {
  final AuthController controller;

  const RegisterScreen({super.key, required this.controller});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _code = TextEditingController();

  bool _hidePassword = true;
  bool _submitted = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await widget.controller.signUp(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _submitted = true);
    }
  }

  Future<void> _verifyEmail() async {
    if (_code.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the complete 6-digit code.')),
      );
      return;
    }

    final success = await widget.controller.verifySignUpCode(
      email: _email.text.trim(),
      code: _code.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AuthLayout(
          child: _submitted ? _verificationForm() : _registrationForm(),
        );
      },
    );
  }

  Widget _brandTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          'POWER OF 4+',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: AppColors.blue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        Text(subtitle, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _errorMessage() {
    final error = widget.controller.errorMessage;

    if (error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        error,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }

  Widget _registrationForm() {
    final auth = widget.controller;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandTitle('Create Your Account', 'Begin your journey in the Word.'),

          const SizedBox(height: 32),

          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email address'),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Email is required';
              }

              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                return 'Enter a valid email';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _password,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: TextButton(
                onPressed: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
                child: Text(_hidePassword ? 'Show' : 'Hide'),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Use at least 8 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPassword,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!auth.isLoading) _register();
            },
            decoration: const InputDecoration(labelText: 'Confirm password'),
            validator: (value) {
              if (value != _password.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          _errorMessage(),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _register,
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Create Account'),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: auth.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Already have an account? Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _verificationForm() {
    final auth = widget.controller;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _brandTitle(
          'Verify Your Email',
          'Enter the 6-digit verification code '
              'sent to ${_email.text.trim()}',
        ),

        const SizedBox(height: 32),

        // SIX DIRECTLY EDITABLE BOXES
        OtpCodeInput(controller: _code),

        _errorMessage(),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: auth.isLoading ? null : _verifyEmail,
          child: auth.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Verify Email'),
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: auth.isLoading
              ? null
              : () {
                  auth.clearError();
                  Navigator.of(context).pop();
                },
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}

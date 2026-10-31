import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/acc_brand_mark.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/otp_code_input.dart';

enum RecoveryStep { email, code, newPassword, completed }

class ForgotPasswordScreen extends StatefulWidget {
  final AuthController controller;

  const ForgotPasswordScreen({super.key, required this.controller});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  RecoveryStep _step = RecoveryStep.email;
  bool _hidePassword = true;

  // STEP 1: REQUEST OTP
  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await widget.controller.requestPasswordReset(
      _email.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _step = RecoveryStep.code);
    }
  }

  // STEP 2: VERIFY OTP
  Future<void> _verifyCode() async {
    if (_code.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the complete 6-digit code.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await widget.controller.verifyRecoveryCode(
      email: _email.text.trim(),
      code: _code.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _step = RecoveryStep.newPassword);
    }
  }

  // STEP 3: UPDATE PASSWORD
  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await widget.controller.changeRecoveredPassword(
      _newPassword.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _step = RecoveryStep.completed);
    }
  }

  // CANCEL RECOVERY
  Future<void> _backToSignIn() async {
    await widget.controller.cancelPasswordRecovery();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return AuthLayout(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),

              const SizedBox(height: 32),

              _buildCurrentStep(),

              if (widget.controller.errorMessage != null &&
                  _step != RecoveryStep.completed) ...[
                const SizedBox(height: 16),
                Text(
                  widget.controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              TextButton(
                onPressed: widget.controller.isLoading ? null : _backToSignIn,
                child: Text(
                  _step == RecoveryStep.completed
                      ? 'Back to Sign In'
                      : 'Cancel and Return to Sign In',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    String title;
    String description;

    switch (_step) {
      case RecoveryStep.email:
        title = 'Forgot Password?';
        description =
            'Enter your email address and we will '
            'send you a verification code.';
        break;

      case RecoveryStep.code:
        title = 'Check Your Email';
        description =
            'Enter the 6-digit verification code '
            'sent to ${_email.text.trim()}';
        break;

      case RecoveryStep.newPassword:
        title = 'Create New Password';
        description = 'Choose a secure password for your account.';
        break;

      case RecoveryStep.completed:
        title = 'Password Updated!';
        description =
            'Your password has been changed successfully. '
            'You can now sign in with your new password.';
        break;
    }

    return Column(
      children: [
        const AccBrandMark(height: 66),
        const SizedBox(height: 12),
        Text(
          'POWER OF 4+  |  THE FRESH PAGE',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: AppColors.primary,
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

        const SizedBox(height: 16),

        Text(description, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case RecoveryStep.email:
        return _emailStep();

      case RecoveryStep.code:
        return _codeStep();

      case RecoveryStep.newPassword:
        return _passwordStep();

      case RecoveryStep.completed:
        return _completedStep();
    }
  }

  // EMAIL ENTRY
  Widget _emailStep() {
    final auth = widget.controller;

    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Email address'),
            onFieldSubmitted: (_) {
              if (!auth.isLoading) _sendCode();
            },
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

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _sendCode,
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send Verification Code'),
          ),
        ],
      ),
    );
  }

  // SIX-BOX OTP ENTRY
  Widget _codeStep() {
    final auth = widget.controller;

    return Column(
      children: [
        OtpCodeInput(controller: _code),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: auth.isLoading ? null : _verifyCode,
          child: auth.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Verify Code'),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: auth.isLoading
              ? null
              : () {
                  auth.clearError();
                  _code.clear();

                  setState(() => _step = RecoveryStep.email);
                },
          child: const Text('Change Email'),
        ),
      ],
    );
  }

  // NEW PASSWORD ENTRY
  Widget _passwordStep() {
    final auth = widget.controller;

    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _newPassword,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New password',
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
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            validator: (value) {
              if (value != _newPassword.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (!auth.isLoading) _savePassword();
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _savePassword,
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  // RECOVERY COMPLETE
  Widget _completedStep() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.blue, size: 64),

        const SizedBox(height: 16),

        const Text('Your account is ready.', textAlign: TextAlign.center),

        const SizedBox(height: 24),

        ElevatedButton(onPressed: _backToSignIn, child: const Text('Sign In')),
      ],
    );
  }
}

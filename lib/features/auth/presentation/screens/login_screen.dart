import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController controller;

  /// True when shown inside the animated welcome page's modal/side panel.
  final bool embedded;

  const LoginScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    // AppGate navigates automatically when the auth session changes.
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    await widget.controller.signInWithGoogle();
  }

  Future<void> _facebook() async {
    FocusScope.of(context).unfocus();
    await widget.controller.signInWithFacebook();
  }

  Future<void> _openRegister() async {
    widget.controller.clearError();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openForgotPassword() async {
    widget.controller.clearError();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(controller: widget.controller),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final auth = widget.controller;
        return AuthLayout(
          embedded: widget.embedded,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'POWER OF 4+',
                    style: GoogleFonts.manrope(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    color: AppColors.navy,
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue your journey in His Word.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    color: const Color(0xFF64768A),
                  ),
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!auth.isLoading) _signIn();
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _hidePassword ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: auth.isLoading ? null : _openForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    auth.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC64646),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 5),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _signIn,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: const Color(0xFF8490A0),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 17),
               
_SocialSignInButton(
                  label: 'Continue with Google',
                  asset: 'asset/google_icon.png',
                  fallbackLetter: 'G',
                  fallbackColor: const Color(0xFF4285F4),
                  onPressed: auth.isLoading ? null : _google,
                ),

                const SizedBox(height: 10),
                
_SocialSignInButton(
                  label: 'Continue with Facebook',
                  asset: 'asset/facebook_icon.png',
                  fallbackLetter: 'f',
                  fallbackColor: const Color(0xFF1877F2),
                  onPressed: auth.isLoading ? null : _facebook,
                ),

                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.navy,
                      ),
                    ),
                    TextButton(
                      onPressed: auth.isLoading ? null : _openRegister,
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



class _SocialSignInButton extends StatelessWidget {
  final String label;
  final String asset;
  final String fallbackLetter;
  final Color fallbackColor;
  final VoidCallback? onPressed;

  const _SocialSignInButton({
    required this.label,
    required this.asset,
    required this.fallbackLetter,
    required this.fallbackColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isFacebook = asset.contains('facebook');

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: const BorderSide(color: Color(0xFFD5E0ED)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8ECF2), width: 1),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(isFacebook ? 1 : 3),
                    child: Image.asset(
                      asset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, _) {
                        return Center(
                          child: Text(
                            fallbackLetter,
                            style: TextStyle(
                              color: fallbackColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_video_background.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

/// Welcome + login presentation only.
/// AuthController, Supabase, AppGate, and role routing stay unchanged.
class AuthEntryScreen extends StatefulWidget {
  final AuthController controller;

  const AuthEntryScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panel;
  bool _formMounted = false;

  @override
  void initState() {
    super.initState();
    _panel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
      reverseDuration: const Duration(milliseconds: 520),
    );
  }

  void _openLogin() {
    if (_formMounted) return;
    widget.controller.clearError();
    setState(() => _formMounted = true);

    if (MediaQuery.disableAnimationsOf(context)) {
      _panel.value = 1;
    } else {
      _panel.forward(from: 0);
    }
  }

  Future<void> _closeLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.clearError();
    if (MediaQuery.disableAnimationsOf(context)) {
      _panel.value = 0;
    } else {
      await _panel.reverse();
    }
    if (mounted) setState(() => _formMounted = false);
  }

  @override
  void dispose() {
    _panel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // IMPORTANT: only one video; it stays mounted during transitions.
          const AuthVideoBackground(),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x53091C35),
                    Color(0x60091C35),
                    Color(0x9A091C35),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 950;
                return AnimatedBuilder(
                  animation: _panel,
                  builder: (context, _) {
                    final t = Curves.easeInOutCubic.transform(_panel.value);
                    return ClipRect(
                      child: compact
                          ? _buildMobile(constraints.biggest, t)
                          : _buildDesktop(constraints.biggest, t),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(Size size, double t) {
    final sheetHeight = size.height * 0.90;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: t > 0.05,
          child: Opacity(
            opacity: 1 - t,
            child: _MobileWelcome(
              onGetStarted: _openLogin,
            ),
          ),
        ),
        if (_formMounted) ...[
          Positioned.fill(
            child: IgnorePointer(
              ignoring: t < 0.8,
              child: GestureDetector(
                onTap: _closeLogin,
                child: ColoredBox(
                  color: Color.fromARGB((51 * t).round(), 0, 0, 0),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: sheetHeight,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * (sheetHeight + 20)),
              child: Material(
                color: const Color(0xFFF9F7F3),
                elevation: 20,
                shadowColor: const Color(0x77091C35),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          Container(
                            height: 4,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD2D6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Close sign in',
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.navy,
                            onPressed: _closeLogin,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                        child: Center(
                          child: LoginScreen(
                            controller: widget.controller,
                            embedded: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktop(Size size, double t) {
    final outerMargin = math.max(28.0, (size.width - 1200) / 2);
    final panelWidth = math.min(450.0, size.width * 0.40);
    final contentWidth = math.min(520.0, size.width * 0.48);
    final centeredLeft = (size.width - contentWidth) / 2;
    final openLeft = outerMargin + 8;
    final contentLeft = centeredLeft + (openLeft - centeredLeft) * t;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: contentLeft,
          width: contentWidth,
          child: Center(
            child: _BrandContent(
              isMobile: false,
              verseReveal: t,
            ),
          ),
        ),
        Positioned(
          bottom: 64,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: t > 0.05,
            child: Opacity(
              opacity: 1 - t,
              child: Center(
                child: _PrimaryWelcomeButton(
                  onPressed: _openLogin,
                  width: 248,
                ),
              ),
            ),
          ),
        ),
        if (_formMounted)
          Positioned(
            top: 24,
            bottom: 24,
            right: outerMargin,
            width: panelWidth,
            child: Transform.translate(
              offset: Offset((1 - t) * (panelWidth + outerMargin + 30), 0),
              child: Material(
                color: const Color(0xF9F9F7F3),
                elevation: 20,
                shadowColor: const Color(0x77091C35),
                borderRadius: BorderRadius.circular(26),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          Tooltip(
                            message: 'Collapse sign in',
                            child: IconButton(
                              onPressed: _closeLogin,
                              icon: const Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                              ),
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 10, 32, 36),
                        child: LoginScreen(
                          controller: widget.controller,
                          embedded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MobileWelcome extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _MobileWelcome({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          children: [
            Positioned(
              left: 24,
              right: 24,
              top: size.height * 0.31,
              child: const _BrandContent(isMobile: true),
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: math.max(34.0, size.height * 0.10),
              child: Center(
                child: _PrimaryWelcomeButton(
                  onPressed: onGetStarted,
                  width: 260,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrandContent extends StatelessWidget {
  final bool isMobile;
  final double verseReveal;

  const _BrandContent({
    required this.isMobile,
    this.verseReveal = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ADELINA CHRISTIAN CHURCH',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: isMobile ? 10.5 : 12.0,
            color: const Color(0xFFE3EBF7),
            fontWeight: FontWeight.w700,
            letterSpacing: isMobile ? 2 : 2.8,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'The Power of 4+',
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: isMobile ? 40.0 : 57.0,
            fontWeight: FontWeight.w600,
            height: 1.12,
            color: Colors.white,
            shadows: const [
              Shadow(color: Color(0x77091C35), blurRadius: 18),
            ],
          ),
        ),
        
const SizedBox(height: 10),

        Text(
          'The Fresh Page',
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: isMobile ? 21 : 26,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
            color: const Color(0xFFEAF2FB),
            shadows: const [Shadow(color: Color(0x66091C35), blurRadius: 12)],
          ),
        ),
        if (!isMobile) ...[
          SizedBox(height: 25 * verseReveal),
          ClipRect(
            child: Align(
              heightFactor: verseReveal,
              child: Opacity(
                opacity: verseReveal,
                child: Column(
                  children: [
                    Text(
                      '“Thy word is a lamp unto my feet,\n'
                      'and a light unto my path.”',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 19,
                        height: 1.6,
                        color: const Color(0xFFF3F5F7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PSALM 119:105  •  KJV',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: const Color(0xFFDCE7F3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryWelcomeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double width;

  const _PrimaryWelcomeButton({
    required this.onPressed,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3478D4),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: const Color(0x55091C35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          'Get Started',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

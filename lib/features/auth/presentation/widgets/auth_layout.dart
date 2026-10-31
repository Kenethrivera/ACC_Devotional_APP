import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_video_background.dart';

/// Shared auth form layout.
/// [embedded] avoids mounting another background/Scaffold inside AuthEntryScreen.
class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool embedded;

  const AuthLayout({
    super.key,
    required this.child,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: child,
    );

    if (embedded) return form;

    final narrow = MediaQuery.sizeOf(context).width < 950;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthVideoBackground(),
          const IgnorePointer(child: ColoredBox(color: Color(0x6607182A))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 16 : 28,
                  vertical: 28,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 22 : 36,
                      vertical: narrow ? 30 : 42,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF7F9F7F2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x66FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44071F3C),
                          blurRadius: 30,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: form,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppMessageType { success, error, warning, info }

class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _activeToast;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    AppMessageType type = AppMessageType.info,
  }) {
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobileLayout = screenWidth < 600;

    if (!kIsWeb || isMobileLayout) {
      // Android and iOS: bottom SnackBar
      final messenger = ScaffoldMessenger.of(context);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Web: top-right floating notification
    _removeToast();

    final Color accent = switch (type) {
      AppMessageType.success => const Color(0xFF238568),
      AppMessageType.error => const Color(0xFFBD4747),
      AppMessageType.warning => const Color(0xFFBC862C),
      AppMessageType.info => AppColors.blue,
    };

    final String title = switch (type) {
      AppMessageType.success => 'Success',
      AppMessageType.error => 'Error',
      AppMessageType.warning => 'Warning',
      AppMessageType.info => 'Information',
    };

    final width = (MediaQuery.sizeOf(context).width - 32)
        .clamp(0.0, 360.0)
        .toDouble();

    final top = MediaQuery.paddingOf(context).top + 20;

    final overlay = Overlay.of(context, rootOverlay: true);

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: top,
          right: 16,
          width: width,
          child: Material(
            color: AppColors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _activeToast = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 4), _removeToast);
  }

  static void _removeToast() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _activeToast;
    _activeToast = null;

    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }
}

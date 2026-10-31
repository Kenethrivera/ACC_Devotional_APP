import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class DashboardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  const DashboardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color = const Color(0xFAFFFFFF),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12102F4E),
            blurRadius: 26,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DashboardSectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const DashboardSectionTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 18,
      runSpacing: 6,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: GoogleFonts.lora(
                color: AppColors.navy,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            description,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardUnavailableNotice extends StatelessWidget {
  final String title;
  final String message;

  const DashboardUnavailableNotice({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DCC5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF927139),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardRoundIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;

  const DashboardRoundIcon({
    super.key,
    required this.icon,
    this.size = 42,
    this.background = AppColors.primarySoft,
    this.foreground = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: foreground, size: size * 0.48),
    );
  }
}

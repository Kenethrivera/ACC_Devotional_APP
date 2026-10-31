import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual tokens scoped to the Daily Devotional Reader.
///
/// The reader deliberately carries its own editorial type and surface system
/// so the approved Stitch treatment does not leak into Module 1 screens.
abstract final class ReaderDesign {
  static const desktopBreakpoint = 1024.0;
  static const mobileBreakpoint = 600.0;
  static const maxContentWidth = 1400.0;

  static const brand = Color(0xFF0F5CA8);
  static const brandHover = Color(0xFF0C4B89);
  static const mobilePrimary = Color(0xFF004482);
  static const navy = Color(0xFF0D1D2C);
  static const body = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const outline = Color(0xFFE2E8F0);
  static const mobileOutline = Color(0xFFC2C6D3);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF8F9FF);
  static const surfaceLow = Color(0xFFEEF4FF);
  static const surfaceContainer = Color(0xFFE4EFFF);
  static const surfaceHigh = Color(0xFFDAEAFF);
  static const inverseSurface = Color(0xFF233242);
  static const inverseOnSurface = Color(0xFFE9F1FF);
  static const secondary = Color(0xFF2A6A48);
  static const amberSurface = Color(0xFFFFFBEB);
  static const amberOutline = Color(0xFFFDE7B0);
  static const error = Color(0xFFBA1A1A);

  static const desktopCardRadius = 20.0;
  static const mobileCardRadius = 32.0;

  static const cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A0F5CA8),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static TextStyle ui({
    required bool mobile,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    final base = mobile
        ? GoogleFonts.plusJakartaSans()
        : GoogleFonts.inter();
    return base.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle editorial({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.newsreader(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static double cardRadius(bool mobile) =>
      mobile ? mobileCardRadius : desktopCardRadius;

  static EdgeInsets cardPadding(bool mobile) =>
      EdgeInsets.all(mobile ? 24 : 28);

  static BoxDecoration cardDecoration(bool mobile) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(cardRadius(mobile)),
        border: Border.all(
          color: mobile ? const Color(0x14132338) : const Color(0xD9E2E8F0),
        ),
        boxShadow: cardShadow,
      );
}

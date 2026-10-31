
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const navy = Color(0xFF102F4E);
  static const primary = Color(0xFF1162B1);
  static const blue = primary;
  static const primaryDark = Color(0xFF0C477F);
  static const sky = Color(0xFF5BA7E1);
  static const skySoft = Color(0xFFCFE6F7);
  static const primarySoft = Color(0xFFE6F2FB);
  static const iceBlue = primarySoft;
  static const white = Color(0xFFFFFFFF);
  static const ivory = Color(0xFFFBF8F1);
  static const sage = Color(0xFFDCEADF);
  static const sageInk = Color(0xFF416F55);
  static const lavender = Color(0xFFE9E4F5);
  static const lavenderInk = Color(0xFF625983);
  static const peach = Color(0xFFF8E1D4);
  static const peachInk = Color(0xFF8B5C45);
  static const gold = Color(0xFFC6A567);
  static const goldSoft = Color(0xFFF3D28F);
  static const border = Color(0xFFD7E3EA);
  static const mutedText = Color(0xFF637789);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ivory,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.gold,
        surface: AppColors.white,
        onSurface: AppColors.navy,
        outline: AppColors.border,
        surfaceContainerHighest: AppColors.primarySoft,
      ),

      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.blue,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

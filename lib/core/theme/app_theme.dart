
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const navy = Color(0xFF173B70);
  static const blue = Color(0xFF3478D4);
  static const iceBlue = Color(0xFFEAF3FC);
  static const white = Color(0xFFFFFFFF);
  static const ivory = Color(0xFFF8F6F0);
  static const gold = Color(0xFFC8A66B);
  static const border = Color(0xFFDCE4ED);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ivory,

      colorScheme: const ColorScheme.light(
        primary: AppColors.blue,
        onPrimary: AppColors.white,
        secondary: AppColors.gold,
        surface: AppColors.white,
        onSurface: AppColors.navy,
      ),

      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.navy,
        elevation: 0,
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
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

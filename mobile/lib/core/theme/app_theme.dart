import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceCard = Color(0xFF1A1A1A);
  static const border = Color(0xFF1F1F1F);
  static const borderLight = Color(0xFF2A2A2A);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF737373);
  static const textMuted = Color(0xFF404040);
  static const positive = Color(0xFF34D399);
  static const positiveSubtle = Color(0xFF052E16);
  static const negative = Color(0xFFF87171);
  static const negativeSubtle = Color(0xFF2C0B0E);
  static const warning = Color(0xFFFBBF24);
  static const warningSubtle = Color(0xFF2D2305);
  static const cream = Color(0xFFEDE8D0);
}

ThemeData buildAppTheme() {
  final base = GoogleFonts.interTextTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cream,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 28, letterSpacing: -0.5),
      headlineMedium: base.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
      titleLarge: base.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
      titleMedium: base.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary, fontSize: 13),
      bodySmall: base.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 11),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.2),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5, space: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceCard,
      contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

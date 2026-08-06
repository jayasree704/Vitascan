// VitaD AI App – Theme & Color System
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const primary = Color(0xFF0058BC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0070EB);
  static const onPrimaryContainer = Color(0xFFFEFCFF);
  static const primaryFixed = Color(0xFFD8E2FF);
  static const primaryFixedDim = Color(0xFFADC6FF);
  static const inversePrimary = Color(0xFFADC6FF);

  // Secondary
  static const secondary = Color(0xFF505F76);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFD0E1FB);
  static const onSecondaryContainer = Color(0xFF54647A);

  // Tertiary
  static const tertiary = Color(0xFF9E3D00);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFC64F00);
  static const onTertiaryContainer = Color(0xFFFFFBFF);

  // Surface
  static const surface = Color(0xFFF9F9FF);
  static const surfaceDim = Color(0xFFD8D9E5);
  static const surfaceBright = Color(0xFFF9F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F3FE);
  static const surfaceContainer = Color(0xFFECEDF9);
  static const surfaceContainerHigh = Color(0xFFE6E8F3);
  static const surfaceContainerHighest = Color(0xFFE0E2ED);
  static const surfaceVariant = Color(0xFFE0E2ED);
  static const inverseSurface = Color(0xFF2D3039);
  static const inverseOnSurface = Color(0xFFEEF0FC);

  // On Surface
  static const onSurface = Color(0xFF181C23);
  static const onSurfaceVariant = Color(0xFF414755);
  static const onBackground = Color(0xFF181C23);
  static const background = Color(0xFFF9F9FF);

  // Outline
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Status Colors
  static const sufficient = Color(0xFF34C759);
  static const insufficient = Color(0xFFFF9500);
  static const deficient = Color(0xFFFF3B30);
  static const statusPink = Color(0xFFFF1E90);
  static const statusPinkLight = Color(0xFFFFD0E5);
}

class AppTextStyles {
  static TextStyle displayLg(BuildContext context) =>
      GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, height: 1.17, letterSpacing: -0.96, color: AppColors.onSurface);

  static TextStyle headlineLg(BuildContext context) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.32, color: AppColors.onSurface);

  static TextStyle headlineLgMobile(BuildContext context) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, height: 1.33, color: AppColors.onSurface);

  static TextStyle headlineMd(BuildContext context) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.onSurface);

  static TextStyle bodyLg(BuildContext context) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w400, height: 1.56, color: AppColors.onSurface);

  static TextStyle bodyMd(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.onSurface);

  static TextStyle labelMd(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, letterSpacing: 0.7, color: AppColors.onSurface);

  static TextStyle dataValue(BuildContext context) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 1, letterSpacing: -0.64, color: AppColors.onSurface);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      indicatorColor: AppColors.primaryFixed,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
        }
        return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant);
      }),
    ),
  );
}

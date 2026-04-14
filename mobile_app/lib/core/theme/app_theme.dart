import 'package:flutter/material.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';

class AppTheme {
  static const Color primary = Color(0xFF004D60);
  static const Color primaryContainer = Color(0xFF00677F);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color surfaceContainer = Color(0xFFECEEEF);
  static const Color surfaceContainerLow = Color(0xFFF0F2F3);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF3F484C);
  static const Color success = Color(0xFF005049);
  static const Color warning = Color(0xFFB06A00);
  static const Color critical = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color tertiaryContainer = Color(0xFFBCEBE2);

  static ThemeData buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      error: critical,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiTokens.radiusLg)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        hintStyle: const TextStyle(color: Color(0x883F484C), fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: surfaceContainer),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          foregroundColor: primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

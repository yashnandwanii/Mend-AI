// File: lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Premium Black Color Palette
  static const Color primaryColor = Color(0xFF6366F1); // Electric Indigo
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan
  static const Color accentColor = Color(0xFF10B981); // Emerald
  static const Color goldAccent = Color(0xFFFFD700); // Gold
  static const Color errorColor = Color(0xFFFF6B6B); // Soft Red
  static const Color warningColor = Color(0xFFFFBE0B); // Amber
  static const Color successColor = Color(0xFF4ECDC4); // Mint

  // Elegant Black Theme Colors
  static const Color pureBlack = Color(0xFF000000);
  static const Color richBlack = Color(0xFF0A0A0A);
  static const Color deepCharcoal = Color(0xFF111111);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color lightGray = Color(0xFF888888);
  static const Color silverText = Color(0xFFE5E5E5);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return darkTheme; // Force dark theme for elegant black experience
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: pureBlack,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: richBlack,
        onSurface: silverText,
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onError: pureWhite,
        outline: darkGray,
        outlineVariant: charcoal,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: silverText, size: 24),
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: pureWhite,
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: silverText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: deepCharcoal,
        hintStyle: const TextStyle(color: lightGray, fontSize: 16),
        labelStyle: const TextStyle(color: silverText, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: charcoal, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: charcoal, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),

      cardTheme: CardThemeData(
        color: richBlack,
        elevation: 12,
        shadowColor: pureBlack.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: charcoal.withValues(alpha: 0.3), width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(color: charcoal, thickness: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepCharcoal,
        contentTextStyle: const TextStyle(color: silverText, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: pureWhite,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: pureWhite,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(color: pureWhite, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(
          color: pureWhite,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        headlineMedium: TextStyle(
          color: pureWhite,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(color: pureWhite, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
          color: silverText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: silverText,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          color: silverText,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: silverText,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodyMedium: TextStyle(
          color: silverText,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: lightGray,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          color: silverText,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: lightGray,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: lightGray,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

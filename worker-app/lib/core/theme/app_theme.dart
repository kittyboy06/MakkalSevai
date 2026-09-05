import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (Worker Edition - High Outdoor Contrast)
  static const Color slateNavy = Color(0xFF0F172A); // Slate 900
  static const Color slateDark = Color(0xFF1E293B); // Slate 800
  static const Color slateMuted = Color(0xFF64748B); // Slate 500
  static const Color slateBorder = Color(0xFFCBD5E1); // Slate 300 (1.5px high contrast)
  static const Color slateLight = Color(0xFFF1F5F9); // Slate 100
  static const Color slateCanvas = Color(0xFFF8FAFC); // Slate 50

  // Status & Availability Colors
  static const Color emeraldOnline = Color(0xFF10B981); // Emerald 500
  static const Color emeraldDark = Color(0xFF059669); // Emerald 600
  static const Color emeraldSurface = Color(0xFFECFDF5); // Emerald 50

  // Urgency & Highlight
  static const Color saffronUrgency = Color(0xFFF59E0B); // Amber/Saffron 500
  static const Color saffronSurface = Color(0xFFFFFBEB); // Amber 50

  // Destructive / Decline
  static const Color crimsonAlert = Color(0xFFEF4444); // Red 500
  static const Color crimsonSurface = Color(0xFFFEF2F2); // Red 50

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: slateCanvas,
      primaryColor: slateNavy,
      colorScheme: const ColorScheme.light(
        primary: slateNavy,
        secondary: emeraldOnline,
        surface: Colors.white,
        error: crimsonAlert,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: slateNavy,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: slateNavy,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: slateNavy,
          letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: slateNavy,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: slateNavy,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: slateDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: slateMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldOnline,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56), // 56px minimum worksite ergonomics
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: slateMuted,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: slateBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: slateBorder, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: slateNavy),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: slateNavy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

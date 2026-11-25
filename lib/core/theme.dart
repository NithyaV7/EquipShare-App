import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Tokens {
  static const primary = Color(0xFF2E7D3A);
  static const primaryLight = Color(0xFFA5D9A7);
  static const background = Color(0xFFF1F8F2);
  static const text = Color(0xFF263338);
  static const warning = Color(0xFFF9AB25);
  static const error = Color(0xFFC0392B);
  static const errorSurface = Color(0xFFFDEAEA);
}

/// Inter for body text, Poppins for titles. Fonts download once, then are cached.
/// If the first launch is offline, the phone's default font is used instead.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Tokens.primary,
    primary: Tokens.primary,
    error: Tokens.error,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.background,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Tokens.background,
      foregroundColor: Tokens.text,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: Tokens.text),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Tokens.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Tokens.primary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Tokens.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

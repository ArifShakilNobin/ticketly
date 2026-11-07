import 'package:flutter/material.dart';

/// Bottle green from the Bangladesh flag – the primary brand colour.
const Color kBrandGreen = Color(0xFF00674B);

/// Red accent from the Bangladesh flag.
const Color kBrandRed = Color(0xFFE30613);

/// Colour used for anything the passenger saves on a fare.
const Color kSavingsColor = Color(0xFF127C56);

/// Background used behind most screens.
const Color kCanvasColor = Color(0xFFF4F6F3);

/// Builds the app-wide Material 3 theme.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBrandGreen,
    secondary: kBrandRed,
    error: kBrandRed,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCanvasColor,
    appBarTheme: AppBarThemeData(
      backgroundColor: kBrandGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7DDD6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7DDD6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBrandGreen, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBrandRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBrandRed, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kBrandGreen.withValues(alpha: 0.12),
      height: 66,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(fontSize: 14, color: Colors.white),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(fontSize: 13),
      side: const BorderSide(color: Color(0xFFD7DDD6)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE6EAE4), thickness: 1),
  );
}

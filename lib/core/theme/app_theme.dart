import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium colors
  static const Color background = Color(0xFF0B0B0B);
  static const Color surface = Color(0xFF141414);
  static const Color surface2 = Color(0xFF1B1B1B);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE7C96B);
  static const Color goldDark = Color(0xFF9C7A16);

  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFBDBDBD);

  static const Color redAccent = Color(0xFFD32F2F);

  static ThemeData darkGoldTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: background,
    primaryColor: gold,

    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: goldLight,
      surface: surface,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: const TextStyle(
        color: textPrimary,
      ),
      bodyMedium: const TextStyle(
        color: textSecondary,
      ),
      bodySmall: const TextStyle(
        color: textSecondary,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: gold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: gold,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: gold),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: gold.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      hintStyle: const TextStyle(color: textSecondary),
      labelStyle: const TextStyle(color: goldLight),
      prefixIconColor: gold,
      suffixIconColor: gold,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: gold.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: gold,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: gold,
        side: const BorderSide(color: gold),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: StadiumBorder(),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      selectedColor: gold,
      secondarySelectedColor: gold,
      labelStyle: const TextStyle(color: textPrimary),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      side: BorderSide(
        color: gold.withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    dividerTheme: DividerThemeData(
      color: gold.withValues(alpha: 0.12),
      thickness: 1,
    ),

    iconTheme: const IconThemeData(color: gold),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: gold,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface2,
      contentTextStyle: const TextStyle(color: textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: textSecondary,
        fontSize: 15,
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: gold,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
            ? gold
            : textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
            ? gold.withValues(alpha: 0.35)
            : Colors.grey.withValues(alpha: 0.3),
      ),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
            ? gold
            : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: gold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );

  // Gold gradient for premium buttons/cards
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
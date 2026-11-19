import 'package:flutter/material.dart';

class AppTheme {
  // Colores primarios
  static const Color primaryColor = Colors.blueAccent;
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  // Colores de texto
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Colors.grey;

  // Colores de calculadora de discos (estilo olímpico)
  static final Color plateRed = Colors.red[800]!;
  static final Color plateBlue = Colors.blue[800]!;
  static final Color plateYellow = Colors.amber[800]!;
  static final Color plateGreen = Colors.green[800]!;
  static final Color plateDefault = Colors.grey[800]!;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,

      // Tema de AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
      ),

      // Tema de tarjetas
      cardTheme: const CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Tema de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: primaryTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Tema de decoración de inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  // Colores de tema claro
  static const Color lightBackgroundColor = Color(0xFFF5F7FA);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightElevatedColor = Color(0xFFEEF2F7);
  static const Color lightBorderColor = Color(0xFFDCE2EC);
  static const Color lightPrimaryTextColor = Color(0xFF111827);
  static const Color lightSecondaryTextColor = Color(0xFF6B7280);
  static const Color lightMutedTextColor = Color(0xFF9CA3AF);

  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: primaryColor,
      secondary: Colors.blueAccent,
      surface: lightSurfaceColor,
      onPrimary: Colors.white,
      onSurface: lightPrimaryTextColor,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackgroundColor,
        foregroundColor: lightPrimaryTextColor,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: lightSurfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightElevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightBorderColor),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? backgroundColor : lightBackgroundColor;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? surfaceColor : lightSurfaceColor;

  static Color elevatedBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF252525) : lightElevatedColor;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A2A2A) : lightBorderColor;

  static Color navBarBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A1A) : lightSurfaceColor;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : lightPrimaryTextColor;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF9E9E9E) : lightSecondaryTextColor;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF666666) : lightMutedTextColor;
}

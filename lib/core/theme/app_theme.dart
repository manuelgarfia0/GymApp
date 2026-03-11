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
}

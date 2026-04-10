import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy     = Color(0xFF0D1B2A);
  static const Color teal     = Color(0xFF1E88A8);
  static const Color orange   = Color(0xFFF4821E);
  static const Color offwhite = Color(0xFFE8EEF4);
  static const Color muted    = Color(0xFF8FA8BF);
  static const Color card     = Color(0xFF162232);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    primaryColor: teal,
    colorScheme: const ColorScheme.dark(
      primary: teal,
      secondary: orange,
      surface: card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: offwhite,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: navy,
      selectedItemColor: teal,
      unselectedItemColor: muted,
    ),
  );
}

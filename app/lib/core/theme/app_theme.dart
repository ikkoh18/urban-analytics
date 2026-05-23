import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy   = Color(0xFF0a0f1e);
  static const Color teal   = Color(0xFF00e5a0);
  static const Color amber  = Color(0xFFffaa00);
  static const Color red    = Color(0xFFff5555);
  static const Color blue   = Color(0xFF5bb8ff);
  static const Color card     = Color(0xFF131929);
  static const Color border   = Color(0x14ffffff); // rgba(255,255,255,0.08)
  static const Color offwhite = Color(0xCCffffff); // branco 80%
  static const Color muted    = Color(0x66ffffff); // branco 40%
  static const Color orange   = Color(0xFFff8c00); // laranja

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    primaryColor: teal,
    colorScheme: const ColorScheme.dark(
      primary: teal,
      secondary: amber,
      surface: card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      elevation: 0,
    ),
  );
}

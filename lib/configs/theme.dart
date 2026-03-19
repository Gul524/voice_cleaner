import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color.fromARGB(255, 154, 216, 243);
  static const Color darkPrimary = Color.fromARGB(255, 45, 83, 95);

  static const Color error = Color.fromARGB(255, 255, 0, 0);
  static const Color warning = Color.fromARGB(255, 255, 179, 0);
  static const Color success = Color.fromARGB(255, 0, 255, 13);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: Color(0xFF12B886),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.grey,
      primaryContainer: Colors.white,
      error: Colors.red,
      errorContainer: Color.fromARGB(255, 232, 90, 80),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: primary),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: Color(0xFF1FD4A3),
      onPrimary: Colors.white,
      surface: Color(0xFF121212),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey,
      primaryContainer: Color(0xFF121212),
      error: Colors.red,
      errorContainer: Color.fromARGB(255, 232, 90, 80),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: darkPrimary),
    ),
  );
}

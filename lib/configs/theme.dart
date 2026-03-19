import 'package:flutter/material.dart';

class _LightColors {
  static const Color primary = Color(0xFF3A6FF7);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF7EA1FF);
  static const Color onPrimaryContainer = Color(0xFF001B5E);

  static const Color secondary = Color(0xFF12B886);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color background = Color(0xFFFFFFFF);

  static const Color primaryTextColor = Color(
    0xFF1F2937,
  );
  static const Color secondaryTextColor = Color(
    0xFF6B7280,
  );
  static const Color deadTextColor = Color(
    0xFFA3A3A3,
  );

  static const Color outline = Color(0xFFE5E5E5);
  static const Color error = Color(0xFFD32F2F);
  static const Color onError = Color(0xFFFFFFFF);
}

class _DarkColors {
  static const Color primary = Color(0xFF5B7FFF);
  static const Color onPrimary = Color(0xFF001B5E);
  static const Color primaryContainer = Color(0xFF3A6FF7);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF1FD4A3);
  static const Color onSecondary = Color(0xFF003D2D);

  static const Color surface = Color(0xFF1F2937);
  static const Color surfaceVariant = Color(0xFF2D3748);
  static const Color background = Color(0xFF111827);

  static const Color primaryTextColor = Color(
    0xFFEBF2FF,
  );
  static const Color secondaryTextColor = Color(
    0xFFB4B8C0,
  );
  static const Color deadTextColor = Color(
    0xFF6B7280,
  );

  static const Color outline = Color(0xFF374151);
  static const Color error = Color(0xFFFF6B6B);
  static const Color onError = Color(0xFF001B5E);
}

class _Gradients {
  static const LinearGradient lightBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F9FF)],
  );

  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111827), Color(0xFF1F2937)],
  );
}

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _LightColors.primary,
      onPrimary: _LightColors.onPrimary,
      primaryContainer: _LightColors.primaryContainer,
      onPrimaryContainer: _LightColors.onPrimaryContainer,
      secondary: _LightColors.secondary,
      onSecondary: _LightColors.onSecondary,
      surface: _LightColors.surface,
      onSurface: _LightColors.primaryTextColor,
      surfaceVariant: _LightColors.surfaceVariant,
      outline: _LightColors.outline,
      error: _LightColors.error,
      onError: _LightColors.onError,
    ),
    scaffoldBackgroundColor: _LightColors.background,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _LightColors.primaryTextColor),
      bodyMedium: TextStyle(color: _LightColors.secondaryTextColor),
      bodySmall: TextStyle(color: _LightColors.deadTextColor),
      labelLarge: TextStyle(color: _LightColors.primaryTextColor),
      labelMedium: TextStyle(color: _LightColors.secondaryTextColor),
      labelSmall: TextStyle(color: _LightColors.deadTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _LightColors.primary,
        foregroundColor: _LightColors.onPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _LightColors.primary,
        foregroundColor: _LightColors.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _LightColors.primary),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _LightColors.secondary,
      foregroundColor: _LightColors.onSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _LightColors.background,
      foregroundColor: _LightColors.primaryTextColor,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _LightColors.surfaceVariant,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: _LightColors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _LightColors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _LightColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      hintStyle: const TextStyle(color: _LightColors.deadTextColor),
      labelStyle: const TextStyle(color: _LightColors.primaryTextColor),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _DarkColors.primary,
      onPrimary: _DarkColors.onPrimary,
      primaryContainer: _DarkColors.primaryContainer,
      onPrimaryContainer: _DarkColors.onPrimaryContainer,
      secondary: _DarkColors.secondary,
      onSecondary: _DarkColors.onSecondary,
      surface: _DarkColors.surface,
      onSurface: _DarkColors.primaryTextColor,
      surfaceVariant: _DarkColors.surfaceVariant,
      outline: _DarkColors.outline,
      error: _DarkColors.error,
      onError: _DarkColors.onError,
    ),
    scaffoldBackgroundColor: _DarkColors.background,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _DarkColors.primaryTextColor),
      bodyMedium: TextStyle(color: _DarkColors.secondaryTextColor),
      bodySmall: TextStyle(color: _DarkColors.deadTextColor),
      labelLarge: TextStyle(color: _DarkColors.primaryTextColor),
      labelMedium: TextStyle(color: _DarkColors.secondaryTextColor),
      labelSmall: TextStyle(color: _DarkColors.deadTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _DarkColors.primary,
        foregroundColor: _DarkColors.onPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _DarkColors.primary,
        foregroundColor: _DarkColors.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _DarkColors.primary),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _DarkColors.secondary,
      foregroundColor: _DarkColors.onSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _DarkColors.surface,
      foregroundColor: _DarkColors.primaryTextColor,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _DarkColors.surfaceVariant,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: _DarkColors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _DarkColors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _DarkColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      hintStyle: const TextStyle(color: _DarkColors.deadTextColor),
      labelStyle: const TextStyle(color: _DarkColors.primaryTextColor),
    ),
  );

  static LinearGradient get lightGradient => _Gradients.lightBackground;

  static LinearGradient get darkGradient => _Gradients.darkBackground;

  static Color getTextColor({
    required Brightness brightness,
    String priority = 'primary',
  }) {
    if (brightness == Brightness.dark) {
      return switch (priority) {
        'secondary' => _DarkColors.secondaryTextColor,
        'dead' => _DarkColors.deadTextColor,
        _ => _DarkColors.primaryTextColor,
      };
    } else {
      return switch (priority) {
        'secondary' => _LightColors.secondaryTextColor,
        'dead' => _LightColors.deadTextColor,
        _ => _LightColors.primaryTextColor,
      };
    }
  }
}

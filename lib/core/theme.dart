import 'package:flutter/material.dart';

class AppTheme {
  // static ThemeData lightTheme = ThemeData(
  //   brightness: Brightness.light,
  //   primaryColor: Colors.purple,
  //   primarySwatch: Colors.purple,
  //   scaffoldBackgroundColor: Colors.white,
  //   colorScheme: ColorScheme.light(
  //     primary: Colors.purple,
  //     secondary: Colors.purpleAccent,
  //     background: Colors.white,
  //     surface: Colors.white,
  //   ),
  //   textTheme: const TextTheme(
  //     bodyLarge: TextStyle(color: Colors.black87),
  //     bodyMedium: TextStyle(color: Colors.black87),
  //     bodySmall: TextStyle(color: Colors.black54),
  //     titleLarge: TextStyle(color: Colors.black87),
  //     titleMedium: TextStyle(color: Colors.black87),
  //     titleSmall: TextStyle(color: Colors.black54),
  //   ),
  //   appBarTheme: const AppBarTheme(
  //     backgroundColor: Colors.transparent,
  //     elevation: 0,
  //     iconTheme: IconThemeData(color: Colors.black87),
  //     titleTextStyle: TextStyle(
  //       color: Colors.black87,
  //       fontSize: 20,
  //       fontWeight: FontWeight.bold,
  //     ),
  //   ),
  // );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.purple,
    primarySwatch: Colors.purple,
    scaffoldBackgroundColor: const Color(0xFF1A0B2E),
    colorScheme: ColorScheme.dark(
      primary: Colors.purple,
      secondary: Colors.purpleAccent,
      background: const Color(0xFF1A0B2E),
      surface: const Color(0xFF2A1B3E),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white70),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

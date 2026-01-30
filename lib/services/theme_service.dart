// import 'package:flutter/material.dart';

// class ThemeService {
//   static final ThemeService _instance = ThemeService._internal();
//   factory ThemeService() => _instance;
//   ThemeService._internal();

//   ThemeMode _themeMode = ThemeMode.system;
//   final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

//   ThemeMode get themeMode => _themeMode;
//   ValueNotifier<ThemeMode> get themeNotifier => _themeNotifier;

//   void setThemeMode(ThemeMode mode) {
//     _themeMode = mode;
//     _themeNotifier.value = mode;
//     // TODO: Save to SharedPreferences for persistence
//     // Example: await SharedPreferences.getInstance().then((prefs) {
//     //   prefs.setString('theme_mode', mode.toString());
//     // });
//   }

//   void toggleTheme() {
//     if (_themeMode == ThemeMode.light) {
//       setThemeMode(ThemeMode.dark);
//     } else if (_themeMode == ThemeMode.dark) {
//       setThemeMode(ThemeMode.light);
//     } else {
//       // If system, switch to light
//       setThemeMode(ThemeMode.light);
//     }
//   }

//   String getThemeModeName() {
//     switch (_themeMode) {
//       case ThemeMode.light:
//         return 'Light';
//       case ThemeMode.dark:
//         return 'Dark';
//       case ThemeMode.system:
//         return 'System';
//     }
//   }
// }


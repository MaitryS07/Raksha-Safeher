import 'package:shared_preferences/shared_preferences.dart';

class ShakePreference {
  static const String _key = "shake_enabled";

  static Future<void> setShakeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<bool> isShakeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;   // default OFF
  }
}

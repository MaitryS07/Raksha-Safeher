import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  double getSensitivity() {
    return _prefs.getDouble('shake_sensitivity') ?? 5.0;
  }

  Future<void> setSensitivity(double value) async {
    await _prefs.setDouble('shake_sensitivity', value);
  }

  bool isPanicGestureEnabled() {
    return _prefs.getBool('panic_gesture_enabled') ?? false;
  }

  Future<void> setPanicGestureEnabled(bool value) async {
    await _prefs.setBool('panic_gesture_enabled', value);
  }

  bool isDistressKeywordEnabled() {
    return _prefs.getBool('distress_keyword_enabled') ?? false;
  }

  Future<void> setDistressKeywordEnabled(bool value) async {
    await _prefs.setBool('distress_keyword_enabled', value);
  }
}
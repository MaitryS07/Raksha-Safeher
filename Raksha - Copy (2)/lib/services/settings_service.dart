/// SettingsService manages app settings including permissions and feature toggles
/// Stores settings in memory (can be extended to use SharedPreferences for persistence)
/// Respects toggle states for microphone and panic gesture detection
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  bool _microphoneEnabled = false;
  bool _panicGestureEnabled = false;

  /// Get current microphone access toggle state
  bool isMicrophoneEnabled() {
    return _microphoneEnabled;
  }

  /// Set microphone access toggle state
  /// When set to false, microphone listening should not start
  void setMicrophoneEnabled(bool enabled) {
    _microphoneEnabled = enabled;
    // TODO: Add SharedPreferences persistence if needed
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('microphone_enabled', enabled);
  }

  /// Get current panic gesture detection toggle state
  bool isPanicGestureEnabled() {
    return _panicGestureEnabled;
  }

  /// Set panic gesture detection toggle state
  /// When set to false, panic gesture detection should not start
  void setPanicGestureEnabled(bool enabled) {
    _panicGestureEnabled = enabled;
    // TODO: Add SharedPreferences persistence if needed
    // Example:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('panic_gesture_enabled', enabled);
  }
}



import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SharedPreferences? _prefs;

  bool _isLoggedIn = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserPhone;
  String? _currentUsername;
  String? _safetyPin;

  /// Initialize storage (call once at app startup)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------- GETTERS ----------

  bool isLoggedIn() => _isLoggedIn;

  String? getCurrentUserId() => _currentUserId;

  String? getCurrentUserEmail() => _currentUserEmail;

  String? getCurrentUserPhone() => _currentUserPhone;

  /// 🔹 Used by SOS auto-call
  String? getUserPhoneNumber() {
    return _currentUserPhone ?? _prefs?.getString("user_phone");
  }

  String? getCurrentUsername() => _currentUsername;

  String? getSafetyPin() => _safetyPin;

  bool verifySafetyPin(String pin) =>
      _safetyPin != null && _safetyPin == pin;

  // ---------- LOGIN ----------

  Future<bool> loginWithEmail(String email, String password) async {
    await init();
    await Future.delayed(const Duration(seconds: 1));

    _isLoggedIn = true;
    _currentUserId = email;
    _currentUserEmail = email;

    // persist session
    await _prefs?.setString("user_email", email);

    return true;
  }

  // ---------- SIGNUP ----------

  Future<bool> signupWithEmail(
    String email,
    String password, {
    String? username,
    String? phone,
    String? safetyPin,
  }) async {
    await init();
    await Future.delayed(const Duration(seconds: 1));

    _currentUserEmail = email;
    _currentUsername = username;
    _currentUserPhone = phone;
    _safetyPin = safetyPin;
    _isLoggedIn = true;
    _currentUserId = email;

    /// 🔹 Persist phone so SOS can auto-call it later
    if (phone != null) {
      await _prefs?.setString("user_phone", phone);
    }

    return true;
  }

  // ---------- LEGACY PHONE LOGIN ----------

  Future<bool> login(String phoneNumber) async {
    await init();
    await Future.delayed(const Duration(seconds: 1));

    _isLoggedIn = true;
    _currentUserId = phoneNumber;
    _currentUserPhone = phoneNumber;

    await _prefs?.setString("user_phone", phoneNumber);

    return true;
  }

  // ---------- LOGOUT ----------

  Future<void> logout() async {
    await init();
    _isLoggedIn = false;

    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserPhone = null;
    _currentUsername = null;
    _safetyPin = null;

    await _prefs?.clear();
  }
}

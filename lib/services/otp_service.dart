import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:http/http.dart' as http;

/// OTPService
/// ------------------------------
/// Uses BACKEND to:
/// 1. Generate OTP
/// 2. Send OTP via SMS (Twilio)
/// 3. Verify OTP entered by user
///
/// No hardcoded OTPs.
/// Fully backend-driven.
class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  /// 🔗 Backend base URL
  /// Must be laptop IPv4 address
  /// Phone & laptop must be on SAME WiFi
  static const String _baseUrl = "http://192.168.17.115:5000";

  // ===================================================
  // 📤 SEND OTP
  // ===================================================
  Future<bool> sendOTP(String phone) async {
    try {
      print("📤 Sending OTP to backend...");

      final res = await http
          .post(
            Uri.parse("$_baseUrl/send_otp"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "phone": phone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        print("✅ OTP sent successfully");
        return true;
      } else {
        print("❌ sendOTP failed (${res.statusCode}): ${res.body}");
        return false;
      }
    } on SocketException {
      print("❌ Network error: Backend not reachable");
      return false;
    } on TimeoutException {
      print("❌ sendOTP timeout");
      return false;
    } catch (e) {
      print("❌ sendOTP exception: $e");
      return false;
    }
  }

  // ===================================================
  // 🔐 VERIFY OTP
  // ===================================================
  Future<bool> verifyOTP(String enteredOTP) async {
    try {
      print("🔐 Verifying OTP with backend...");

      final res = await http
          .post(
            Uri.parse("$_baseUrl/verify_otp"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "otp": enteredOTP,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        print("✅ OTP verified");
        return true;
      } else {
        print("❌ verifyOTP failed (${res.statusCode}): ${res.body}");
        return false;
      }
    } on SocketException {
      print("❌ Network error during OTP verify");
      return false;
    } on TimeoutException {
      print("❌ verifyOTP timeout");
      return false;
    } catch (e) {
      print("❌ verifyOTP exception: $e");
      return false;
    }
  }
}

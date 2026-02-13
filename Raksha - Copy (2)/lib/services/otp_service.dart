import 'package:flutter/foundation.dart';
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
  static const String _baseUrl = "http://192.168.17.116:5000";

  // ===================================================
  // 📤 SEND OTP
  // ===================================================
  Future<bool> sendOTP(String phone) async {
    try {
      debugPrint("📤 Sending OTP to backend...");

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
        debugPrint("✅ OTP sent successfully");
        return true;
      } else {
        debugPrint("❌ sendOTP failed (${res.statusCode}): ${res.body}");
        return false;
      }
    } on SocketException {
      debugPrint("❌ Network error: Backend not reachable");
      return false;
    } on TimeoutException {
      debugPrint("❌ sendOTP timeout");
      return false;
    } catch (e) {
      debugPrint("❌ sendOTP exception: $e");
      return false;
    }
  }

  // ===================================================
  // 🔐 VERIFY OTP
  // ===================================================
  Future<bool> verifyOTP(String enteredOTP) async {
    try {
      debugPrint("🔐 Verifying OTP with backend...");

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
        debugPrint("✅ OTP verified");
        return true;
      } else {
        debugPrint("❌ verifyOTP failed (${res.statusCode}): ${res.body}");
        return false;
      }
    } on SocketException {
      debugPrint("❌ Network error during OTP verify");
      return false;
    } on TimeoutException {
      debugPrint("❌ verifyOTP timeout");
      return false;
    } catch (e) {
      debugPrint("❌ verifyOTP exception: $e");
      return false;
    }
  }
}

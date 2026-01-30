import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Change this to your backend machine IP
  /// For Android emulator → use "http://10.0.2.2:5000"
  /// For physical device (same Wi-Fi) → keep your local IP
  static const String backendUrl = "http://192.168.17.115:5000";

  // ────────────────────────────────────────────────
  //  NEW METHOD – ADD ONE GUARDIAN TO BACKEND
  // ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> addGuardian(String phone) async {
    final url = Uri.parse("$backendUrl/add_guardian");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"guardian_phone": phone}),
      );

      print("→ POST /add_guardian → status: ${res.statusCode} | body: ${res.body}");

      return {
        "success": res.statusCode == 200,
        "status": res.statusCode,
        "response": res.body.isNotEmpty ? jsonDecode(res.body) : {},
      };
    } catch (e) {
      print("Error in addGuardian: $e");
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }

  // ────────────────────────────────────────────────
  //  EXISTING METHODS (unchanged)
  // ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> configureBackend({
    required String twilioSid,
    required String twilioAuth,
    required String twilioNumber,
    required String userPhone,
    required List<String> guardians,
    required String safePin,
  }) async {
    final url = Uri.parse("$backendUrl/configure");
    final payload = {
      "twilio_sid": twilioSid,
      "twilio_auth": twilioAuth,
      "twilio_number": twilioNumber,
      "user_phone": userPhone,
      "guardians": guardians,
      "safe_pin": safePin,
    };
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      return {
        "success": res.statusCode == 200,
        "status": res.statusCode,
        "response": jsonDecode(res.body),
      };
    } catch (e) {
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> triggerSOS({String pin = ""}) async {
    final url = Uri.parse("$backendUrl/sos_trigger");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pin": pin}),
      );
      return {
        "success": res.statusCode == 200,
        "status": res.statusCode,
        "response": jsonDecode(res.body),
      };
    } catch (e) {
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }

  static Future<void> updateLocation(String latLng) async {
    final url = Uri.parse("$backendUrl/update_location");
    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"location": latLng}),
    );
  }
}
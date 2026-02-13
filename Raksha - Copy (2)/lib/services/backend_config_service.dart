import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendConfigService {
  static const baseUrl = "http://192.168.17.116:5000";

  static Future<bool> configureBackend({
    required String twilioSid,
    required String twilioAuth,
    required String twilioNumber,
    required String userPhone,
    required List<String> guardians,
    required String safePin,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/configure"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "twilio_sid": twilioSid,
        "twilio_auth": twilioAuth,
        "twilio_number": twilioNumber,
        "user_phone": userPhone,
        "guardians": guardians,
        "safe_pin": safePin
      }),
    );

    return res.statusCode == 200;
  }
}

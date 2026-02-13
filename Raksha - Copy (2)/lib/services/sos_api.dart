import 'dart:convert';
import 'package:http/http.dart' as http;

const backend = "http://192.168.17.116:5000"; // change to your server IP

class SosApi {

  static Future<void> signup(String phone, String pin) async {
    await http.post(
      Uri.parse("$backend/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_phone": phone, "pin": pin}),
    );
  }

  static Future<void> updateGuardians(List<String> guardians) async {
    await http.post(
      Uri.parse("$backend/update_guardians"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"guardians": guardians}),
    );
  }

  static Future<void> triggerSOS(String locationUrl) async {
    await http.post(
      Uri.parse("$backend/sos_trigger"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"location": locationUrl}),
    );
  }

  static Future<void> sendLocation(String locationUrl) async {
    await http.post(
      Uri.parse("$backend/update_location"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"location": locationUrl}),
    );
  }

  static Future<bool> cancelSOS(String pin) async {
    final res = await http.post(
      Uri.parse("$backend/cancel_sos"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"pin": pin}),
    );
    return res.statusCode == 200;
  }

  static Future<void> guardianAck() async {
    await http.post(Uri.parse("$backend/guardian_ack"));
  }
}

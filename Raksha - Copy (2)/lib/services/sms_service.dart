import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  /// 📞 REAL phone call to the user
  Future<void> callEmergencyNumber(String number) async {
    final uri = Uri(scheme: "tel", path: number);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint("⚠️ Could not launch phone call to $number");
    }
  }

  /// 📨 SMS sending now handled by BACKEND (Twilio)
  /// We keep this method for compatibility but do NOT send SMS locally
  Future<void> sendEmergencySMS(List<String> numbers, String message) async {
    debugPrint("📨 SMS sending is handled by backend via Twilio");
    debugPrint("Guardians: ${numbers.join(', ')}");
    debugPrint("Message: $message");
  }
}

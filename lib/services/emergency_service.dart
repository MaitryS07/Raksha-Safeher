import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shake_service.dart';

class EmergencyService {
  EmergencyService._private();
  static final EmergencyService _instance = EmergencyService._private();
  factory EmergencyService() => _instance;

  static const String backendUrl = "http://192.168.17.115:5000";

  bool _isEmergencyActive = false;
  StreamSubscription<Position>? _locationSub;

  bool get isEmergencyActive => _isEmergencyActive;

  // --------------------------------------------------
  // 🚨 ACTIVATE SOS
  // --------------------------------------------------
  Future<void> activateEmergency({double? lat, double? lng}) async {
    if (_isEmergencyActive) {
      print("⚠️ SOS already active");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId == null) {
      print("❌ Cannot trigger SOS: user_id missing");
      return;
    }

    _isEmergencyActive = true;
    print("🔥 Sending SOS for user: $userId");

    if (lat == null || lng == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        print("⚠️ GPS error: $e");
      }
    }

    final payload = {
      "user_id": userId,
      "location": (lat != null && lng != null) ? "$lat,$lng" : "unknown",
    };

    try {
      final res = await http.post(
        Uri.parse("$backendUrl/sos_trigger"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🚨 SOS Response: ${res.statusCode} → ${res.body}");

      if (res.statusCode == 200) {
        _startLiveLocationUpdates(userId);
      } else {
        _isEmergencyActive = false;
      }
    } catch (e) {
      print("❌ SOS failed: $e");
      _isEmergencyActive = false;
    }
  }

  // --------------------------------------------------
  // 🛑 CANCEL SOS
  // --------------------------------------------------
  Future<bool> cancelEmergency(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (!_isEmergencyActive || userId == null) return false;

    try {
      final res = await http.post(
        Uri.parse("$backendUrl/cancel_sos"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pin": pin, "user_id": userId}),
      );

      if (res.statusCode == 200) {
        _isEmergencyActive = false;
        _locationSub?.cancel();
        _locationSub = null;
        ShakeService().resetSOSLock();
        return true;
      }
    } catch (e) {
      print("❌ Cancel SOS failed: $e");
    }

    return false;
  }

  // --------------------------------------------------
  // 📍 UPDATE LOCATION
  // --------------------------------------------------
  Future<void> updateLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    if (userId == null) return;

    try {
      await http.post(
        Uri.parse("$backendUrl/update_location"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "location": "$lat,$lng",
        }),
      );
    } catch (e) {
      print("⚠️ Location update failed: $e");
    }
  }

  // --------------------------------------------------
  // 📍 LIVE LOCATION
  // --------------------------------------------------
  void _startLiveLocationUpdates(String userId) {
    _locationSub?.cancel();

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (_isEmergencyActive) {
        updateLocation(pos.latitude, pos.longitude);
      }
    });
  }
}

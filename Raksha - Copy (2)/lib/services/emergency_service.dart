import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'shake_service.dart';   // needed to reset shake lock

class EmergencyService {

  // -------- SINGLETON --------
  EmergencyService._private();
  static final EmergencyService _instance = EmergencyService._private();
  factory EmergencyService() => _instance;

  // 🔹 USE 10.0.2.2 for Android Emulator, or your LAN IP for physical device
  static const String backendUrl = "http://192.168.17.116:5000";

  bool _isEmergencyActive = false;
  StreamSubscription<Position>? _locationSub;

  bool get isEmergencyActive => _isEmergencyActive;
  
  // 🔄 SYNC STATE WITH BACKEND
  Future<void> checkBackendState() async {
    try {
      final res = await http.get(Uri.parse("$backendUrl/"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        bool serverActive = data["sos_active"] ?? false;
        
        if (_isEmergencyActive != serverActive) {
           debugPrint("🔄 SYNC: Local($_isEmergencyActive) != Server($serverActive) -> Updating Local");
           _isEmergencyActive = serverActive;
           if (!_isEmergencyActive) {
             ShakeService().resetSOSLock();
           }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to sync backend state: $e");
    }
  }

  // --------------------------------------------------
  // 🚨 ACTIVATE SOS
  // --------------------------------------------------
  Future<void> activateEmergency({double? lat, double? lng}) async {

    if (_isEmergencyActive) {
      debugPrint("⚠️ SOS already active — skipping duplicate trigger");
      return;
    }

    _isEmergencyActive = true;
    debugPrint("🔥 Sending SOS to backend…");

    // Auto-fetch location if not provided
    if (lat == null || lng == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        debugPrint("⚠️ Could not fetch GPS location: $e");
      }
    }

    final payload = {
      "location": (lat != null && lng != null) ? "$lat,$lng" : "unknown",
    };

    try {
      final res = await http.post(
        Uri.parse("$backendUrl/sos_trigger"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint("🚨 Backend SOS Response: ${res.statusCode} → ${res.body}");

      // Start live location only if SOS really started
      if (res.statusCode == 200) {
        _startLiveLocationUpdates();
      }

    } catch (e) {
      debugPrint("❌ SOS trigger failed (network/backend issue): $e");
      _isEmergencyActive = false;   // rollback on failure
    }
  }

  // --------------------------------------------------
  // 🛑 CANCEL SOS WITH PIN
  // --------------------------------------------------
  Future<bool> cancelEmergency(String pin) async {

    if (!_isEmergencyActive) {
      debugPrint("ℹ️ No active SOS to cancel");
      return false;
    }

    debugPrint("🟢 Sending PIN cancel to backend…");

    try {
      final res = await http.post(
        Uri.parse("$backendUrl/cancel_sos"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pin": pin}),
      );

      debugPrint("🟢 Cancel Response: ${res.statusCode} → ${res.body}");

      if (res.statusCode == 200) {
        _isEmergencyActive = false;

        // 🔹 STOP live location stream
        _stopLiveLocationUpdates();

        // 🔹 Reset shake lock so next shake works
        ShakeService().resetSOSLock();

        debugPrint("✅ SOS cancelled locally + backend");
        return true;
      }

    } catch (e) {
      debugPrint("❌ Failed to cancel SOS: $e");
    }

    return false;
  }

  // --------------------------------------------------
  // 📍 UPDATE LOCATION ONCE
  // --------------------------------------------------
  Future<void> updateLocation(double lat, double lng) async {
    try {
      final res = await http.post(
        Uri.parse("$backendUrl/update_location"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"location": "$lat,$lng"}),
      );

      debugPrint("📍 Location update: ${res.statusCode}");
    } catch (e) {
      debugPrint("⚠️ Location update failed: $e");
    }
  }

  // --------------------------------------------------
  // 📍 LIVE LOCATION DURING SOS (SAFE VERSION)
  // --------------------------------------------------
  void _startLiveLocationUpdates() {
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

  void _stopLiveLocationUpdates() {
    _locationSub?.cancel();
    _locationSub = null;
    debugPrint("📍 Live location updates STOPPED");
  }
}

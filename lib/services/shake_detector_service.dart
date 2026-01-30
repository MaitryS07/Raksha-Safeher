import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../screens/emergency_hud_screen.dart';
import '../main.dart';
import 'emergency_service.dart';

class ShakeDetectorService {
  /// Sensitivity tuning
  static const double shakeThreshold = 2.6;    // slightly safer
  static const int minShakeCount = 3;
  static const int shakeGapMs = 900;

  /// Safety controls
  static const int sosCooldownMs = 9000;       // prevents multiple triggers

  static int _shakeCount = 0;
  static int _lastShakeTime = 0;
  static int _lastSosTime = 0;
  static bool _hudOpen = false;

  static void start() {
    print("📡 Shake listener started…");

    accelerometerEvents.listen((event) async {
      final gX = event.x / 9.81;
      final gY = event.y / 9.81;
      final gZ = event.z / 9.81;

      final gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce < shakeThreshold) return;

      final now = DateTime.now().millisecondsSinceEpoch;

      // avoid rapid false events
      if ((now - _lastShakeTime) < shakeGapMs) return;

      _lastShakeTime = now;
      _shakeCount++;

      print("🌀 Shake detected count = $_shakeCount");

      if (_shakeCount < minShakeCount) return;

      _shakeCount = 0; // reset counter

      /// --------- Cooldown protection ----------
      if ((now - _lastSosTime) < sosCooldownMs) {
        print("⏳ SOS cooldown active — ignoring repeat trigger");
        return;
      }

      _lastSosTime = now;
      print("🚨 SHAKE CONFIRMED — ACTIVATING SOS");

      final service = EmergencyService();

      if (!service.isEmergencyActive) {
        double lat = 0.0;
        double lng = 0.0;

        try {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition();
            lat = pos.latitude;
            lng = pos.longitude;
          } else {
            final last = await Geolocator.getLastKnownPosition();
            if (last != null) {
              lat = last.latitude;
              lng = last.longitude;
            }
          }
        } catch (e) {
          print("⚠️ GPS unavailable — continuing without location");
        }

        await service.activateEmergency(lat: lat, lng: lng);
      }

      /// --------- Open Emergency HUD (only once) ----------
      if (!_hudOpen) {
        _hudOpen = true;

        navigatorKey.currentState
            ?.push(MaterialPageRoute(builder: (_) => const EmergencyHUD()))
            .then((_) => _hudOpen = false);
      }
    });
  }
}

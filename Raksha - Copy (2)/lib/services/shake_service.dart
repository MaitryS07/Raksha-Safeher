import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

import 'emergency_service.dart';

typedef ShakeCallback = void Function();

class ShakeService {
  static final ShakeService _instance = ShakeService._internal();
  factory ShakeService() => _instance;
  ShakeService._internal();

  bool _isListening = false;
  ShakeCallback? _onShake;

  double _sensitivity = 5.0;

  static const int _minShakes = 3;
  static const int _shakeGapMs = 350; // was 600
  static const int _cooldownMs = 25000; // matches backend delay

  int _shakeCount = 0;
  int _lastShakeTime = 0;

  bool _sosInProgress = false;

  StreamSubscription<AccelerometerEvent>? _sub;

  // ---------------- SETTINGS ----------------
  void setSensitivity(double value) {
    _sensitivity = value.clamp(1.0, 10.0);
  }

  double getSensitivity() => _sensitivity;
  bool isListening() => _isListening;

  // ---------------- START LISTENING ----------------
  void startListening(ShakeCallback onShake) {
    stopListening(); // clean restart

    _isListening = true;
    _onShake = onShake;
    _shakeCount = 0;
    _lastShakeTime = 0;
    _sosInProgress = false;

    _sub = accelerometerEvents.listen(_processEvent);
    debugPrint("📡 Shake detection ON (Sensitivity: $_sensitivity, Gap: ${_shakeGapMs}ms)");
  }

  // ---------------- PROCESS SENSOR DATA ----------------
  void _processEvent(AccelerometerEvent event) {
    if (!_isListening) return;
    if (_sosInProgress) return;

    final double gX = event.x / 9.81;
    final double gY = event.y / 9.81;
    final double gZ = event.z / 9.81;

    final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    // Dynamic threshold based on sensitivity (1.0 -> 3.75g, 5.0 -> 2.75g, 10.0 -> 1.5g)
    double threshold = 1.5 + ((10 - _sensitivity) * 0.25);

    if (gForce > threshold) {
      final int now = DateTime.now().millisecondsSinceEpoch;

      if (_lastShakeTime > 0 && (now - _lastShakeTime) < _shakeGapMs) {
        return; // ignore rapid multi-shocks from 1 shake
      }

      _shakeCount++;
      _lastShakeTime = now;
      debugPrint("📳 SHAKE DETECTED! gForce: ${gForce.toStringAsFixed(2)} Threshold: $threshold Count: $_shakeCount");

      if (_shakeCount >= _minShakes) {
        _triggerSOS();
      }
    }
  }

  // ---------------- SOS TRIGGER ----------------
  void _triggerSOS() {
    if (_onShake == null) return;
    if (_sosInProgress) return;

    _sosInProgress = true;

    debugPrint("🚨 SHAKE CONFIRMED — ACTIVATING SOS");

    EmergencyService().activateEmergency();
    _onShake!.call();

    Future.delayed(const Duration(milliseconds: _cooldownMs), () {
      _sosInProgress = false;
      _shakeCount = 0;
      _lastShakeTime = 0;
      debugPrint("🔄 SOS lock auto-reset");
    });
  }

  // ---------------- MANUAL RESET AFTER PIN ----------------
  void resetSOSLock() {
    _sosInProgress = false;
    _shakeCount = 0;
    _lastShakeTime = 0;
    debugPrint("🔄 SOS Manual Reset (Lock Cleared)");
  }

  // ---------------- NORMAL STOP (temporary pause) ----------------
  void stopListening() {
    _isListening = false;
    _onShake = null;
    _shakeCount = 0;
    _lastShakeTime = 0;
    _sosInProgress = false;

    _sub?.cancel();
    _sub = null;

    debugPrint("🛑 Shake detection OFF");
  }

  // ---------------- 🔴 NEW METHOD YOU WERE MISSING ----------------
  void stopListeningCompletely() {
    _isListening = false;
    _onShake = null;
    _shakeCount = 0;
    _lastShakeTime = 0;
    _sosInProgress = false;

    _sub?.cancel();
    _sub = null;

    debugPrint("🛑 Shake detection FULLY STOPPED");
  }
}

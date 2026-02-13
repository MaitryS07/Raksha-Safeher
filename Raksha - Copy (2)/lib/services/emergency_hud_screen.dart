import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/emergency_service.dart';
import '../services/shake_service.dart';

class EmergencyHUD extends StatefulWidget {
  const EmergencyHUD({super.key});

  @override
  State<EmergencyHUD> createState() => _EmergencyHUDState();
}

class _EmergencyHUDState extends State<EmergencyHUD> {
  final EmergencyService _emergencyService = EmergencyService();
  final TextEditingController _pinController = TextEditingController();

  static const int _startSeconds = 20;
  int _seconds = _startSeconds;
  Timer? _uiTimer;
  bool _finished = false;
  bool _emergencySent = false; // NEW: track if we already alerted guardians

  Position? _lastPosition; // Store location for later use

  @override
  void initState() {
    super.initState();
    if (_uiTimer == null) {
      _startEmergencyFlow();
    }
  }

  Future<void> _startEmergencyFlow() async {
    // 1. Try to get fresh location (even if we don't send yet)
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        _lastPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
      }
    } catch (_) {
      // silent fail – we'll use last known or "unknown"
    }

    // 2. Start countdown – DO NOT send alert yet
    _startCountdown();
  }

  void _startCountdown() {
    _uiTimer?.cancel(); // safety
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _finished || _seconds <= 0) {
        timer.cancel();
        if (mounted && !_finished) {
          setState(() => _seconds = 0);
          _handleTimeout();
        }
        return;
      }

      setState(() {
        _seconds--;
      });
    });
  }

  Future<void> _handleTimeout() async {
    if (_finished) return;
    _finished = true;

    // Only now send the real emergency alert
    if (!_emergencySent) {
      await _emergencyService.activateEmergency(
        lat: _lastPosition?.latitude,
        lng: _lastPosition?.longitude,
      );
      _emergencySent = true;
      // Optional: show snackbar or change UI to "Help is on the way"
    }

    _finishAndExit();
  }

  void _finishAndExit() {
    if (_finished) return;
    _finished = true;
    _uiTimer?.cancel();
    _uiTimer = null;
    _pinController.clear();

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _cancelSOS() async {
    if (_finished) return;

    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    final cancelled = await _emergencyService.cancelEmergency(pin);
    if (cancelled) {
      // If backend supports it – tell backend to cancel pending alert
      ShakeService().resetSOSLock();
      _finishAndExit();
    } else {
      // Optional: show error "Wrong PIN"
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(  // Better than WillPopScope in newer Flutter
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "🚨 EMERGENCY SOS ACTIVATED",
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
              const SizedBox(height: 16),

              if (_finished)
                const Text(
                  "SOS SENT!\nHelp is on the way",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold),
                )
              else ...[
                Text(
                  _seconds.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _pinController,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    enabled: !_finished,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    decoration: InputDecoration(
                      hintText: "PIN to cancel",
                      hintStyle: const TextStyle(color: Colors.grey),
                      counterText: "",
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _finished ? null : _cancelSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text("Cancel SOS", style: TextStyle(fontSize: 18)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
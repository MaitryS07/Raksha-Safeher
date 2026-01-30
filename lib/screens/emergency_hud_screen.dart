import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/sos_api.dart';
import '../services/sos_controller.dart';

class EmergencyHUD extends StatefulWidget {
  const EmergencyHUD({super.key});

  @override
  State<EmergencyHUD> createState() => _EmergencyHUDState();
}

class _EmergencyHUDState extends State<EmergencyHUD> {
  final TextEditingController _pinController = TextEditingController();

  int _seconds = 20;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _startEmergencyFlow();
  }

  /// 🚨 Start SOS + GPS tracking
  Future<void> _startEmergencyFlow() async {
    double lat = 0, lng = 0;

    // 📍 Get location (if permission granted)
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    final locationUrl = "https://maps.google.com/?q=$lat,$lng";

    // 🚨 Trigger backend SOS (call + 20s wait)
    await SosApi.triggerSOS(locationUrl);

    // 🔁 Start live GPS updates every 5 sec
    SosController.startSOS();

    // ⏱ UI countdown
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) {
  print("⏱ 20 seconds over — waiting for backend result");
}

    });
  }

  /// 🟢 Cancel SOS (PIN)
  Future<void> _cancelSOS() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    final ok = await SosApi.cancelSOS(pin);

    if (ok) {
      SosController.stopSOS();
      _closeScreen();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SOS cancelled — You are safe")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid PIN")),
      );
    }
  }

  void _closeScreen() {
    SosController.stopSOS(); // stop GPS loop
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pinController.dispose();
    SosController.stopSOS();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "🚨 EMERGENCY SOS ACTIVATED",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "$_seconds",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "Seconds remaining",
                style: TextStyle(color: Colors.white60),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: 220,
                child: TextField(
                  controller: _pinController,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    hintText: "Enter PIN to cancel",
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    counterText: "",
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 8,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _cancelSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: const Text("Cancel SOS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

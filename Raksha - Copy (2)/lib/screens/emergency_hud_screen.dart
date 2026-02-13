import 'dart:async';
import 'package:flutter/material.dart';
import '../services/emergency_service.dart';

class EmergencyHUD extends StatefulWidget {
  const EmergencyHUD({super.key});

  @override
  State<EmergencyHUD> createState() => _EmergencyHUDState();
}

class _EmergencyHUDState extends State<EmergencyHUD> {
  final TextEditingController _pinController = TextEditingController();
  final EmergencyService _emergencyService = EmergencyService();

  int _seconds = 20;
  Timer? _uiTimer;
  bool _sosCancelled = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startEmergencyFlow();
  }

  /// 🚨 Start SOS Flow
  void _startEmergencyFlow() {
    // 1. Start the countdown timer
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _uiTimer?.cancel();
        // Timer finished -> logic is handled by backend (server-side wait)
        // But we can show a status update here if needed
      }
    });

    // 2. Trigger Backend SOS (if not already active)
    // The background service might have triggered it already, or this screen might trigger it.
    // EmergencyService handles duplicate checks internally.
    _emergencyService.activateEmergency();
  }

  /// 🟢 Cancel SOS (PIN)
  Future<void> _cancelSOS() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final success = await _emergencyService.cancelEmergency(pin);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      _uiTimer?.cancel();
      setState(() => _sosCancelled = true);

      // Show success message and close after delay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("SOS Cancelled — You are safe"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid PIN. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
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
    if (_sosCancelled) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 16),
              Text(
                "YOU ARE SAFE",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "SOS Cancelled",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: true, // Allow system back button
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 60),
               const SizedBox(height: 16),
              const Text(
                "EMERGENCY SOS",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 40),

              // 🔙 BACK BUTTON (Added for safety/UX)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                  onPressed: () {
                     Navigator.of(context).pop();
                  },
                ),
              ),

              // TIMER
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: _seconds / 20,
                      strokeWidth: 10,
                      color: Colors.red,
                      backgroundColor: Colors.red.withOpacity(0.2),
                    ),
                  ),
                  Text(
                    "$_seconds",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                "Sending alerts to guardians...",
                style: TextStyle(color: Colors.white54),
              ),

              const SizedBox(height: 50),

              // PIN INPUT
              TextField(
                controller: _pinController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "Enter PIN",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 20, letterSpacing: 2),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _cancelSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "CANCEL SOS",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../services/shake_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/mic_listen_service.dart';
import '../core/utils.dart';

import 'auth_screen.dart';
import 'emergency_hud_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final ShakeService _shakeService = ShakeService();
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();

  late double sensitivity;
  late bool _panicGestureEnabled;
  late bool _distressKeywordEnabled;

  @override
  void initState() {
    super.initState();

    sensitivity = _shakeService.getSensitivity();
    _panicGestureEnabled = _shakeService.isListening(); // 🔥 real panic state
    _distressKeywordEnabled = MicListenService.micEnabled; // 🔥 real mic state

    WidgetsBinding.instance.addObserver(this);
    _checkMicrophonePermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------
  // Permission check
  // ---------------------------
  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted && mounted) {
      setState(() => _distressKeywordEnabled = false);
      MicListenService.stopListening();
    }
  }

  // ---------------------------
  // 🔥 FIXED MIC TOGGLE
  // ---------------------------
  Future<void> _handleDistressKeywordToggle(bool value) async {
    if (value == MicListenService.micEnabled) return;

    setState(() => _distressKeywordEnabled = value); // ✅ instant UI change

    if (value) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() => _distressKeywordEnabled = false);
        return;
      }
      MicListenService.startListening(); // don't await
    } else {
      MicListenService.stopListening();
    }

    _settingsService.setDistressKeywordEnabled(value);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 120);
    }
  }

  // ---------------------------
  // Panic gesture toggle
  // ---------------------------
  void _handlePanicGestureToggle(bool value) {
    setState(() => _panicGestureEnabled = value);

    if (value) {
      _startShakeDetection();
    } else {
      _shakeService.stopListeningCompletely();
    }

    _settingsService.setPanicGestureEnabled(value);
  }

  void _startShakeDetection() {
    _shakeService.startListening(() {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmergencyHUD()),
        );
      }
    });
  }

  // ---------------------------
  // Logout
  // ---------------------------
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Log Out", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      _shakeService.stopListeningCompletely();
      MicListenService.stopListening();
      await _authService.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
    }
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Hub")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Shake Sensitivity", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 1,
            max: 10,
            value: sensitivity,
            onChanged: (v) {
              setState(() => sensitivity = v);
              _shakeService.setSensitivity(v);
            },
          ),
          const Divider(height: 32),

          SwitchListTile(
            title: const Text("Distress Keyword Detection"),
            subtitle: const Text("Auto-trigger SOS on voice distress"),
            secondary: const Icon(Icons.hearing, color: Colors.red),
            value: _distressKeywordEnabled,
            onChanged: _handleDistressKeywordToggle,
          ),

          SwitchListTile(
            title: const Text("Panic Gesture Detection"),
            subtitle: const Text("Enable shake-gesture SOS trigger"),
            secondary: const Icon(Icons.vibration),
            value: _panicGestureEnabled,
            onChanged: _handlePanicGestureToggle,
          ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}

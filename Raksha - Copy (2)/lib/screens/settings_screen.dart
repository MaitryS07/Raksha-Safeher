import 'package:flutter/material.dart';

import '../services/background_service.dart';
import '../services/shake_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/mic_listen_service.dart';

import 'auth_screen.dart';
import 'emergency_hud_screen.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {

  final ShakeService _shakeService = ShakeService();
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();

  late double sensitivity;
  late bool _microphoneEnabled;
  late bool _panicGestureEnabled;

  @override
  void initState() {
    super.initState();

    sensitivity = _shakeService.getSensitivity();
    _microphoneEnabled = _settingsService.isMicrophoneEnabled();
    _panicGestureEnabled = _settingsService.isPanicGestureEnabled();

    WidgetsBinding.instance.addObserver(this);
    _checkMicrophonePermission();

    // Restart shake ONLY if user had enabled it before
    if (_panicGestureEnabled) {
      _startShakeDetection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------- APP LIFECYCLE ----------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMicrophonePermission();

      // Keep shake alive if toggle is ON
      if (_panicGestureEnabled && !_shakeService.isListening()) {
        _startShakeDetection();
      }
    }
  }

  // ---------------- MICROPHONE PERMISSION ----------------
  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (!status.isGranted) {
      setState(() => _microphoneEnabled = false);
      _settingsService.setMicrophoneEnabled(false);
      MicListenService.stopListening();
    }
  }

  // ---------------- BACKGROUND SERVICE COMMAND ----------------
  Future<void> _sendMicCommand(bool enable) async {
    final service = FlutterBackgroundService();

    if (enable) {
      await service.startService();
      service.invoke("mic_on");
    } else {
      service.invoke("mic_off");
    }
  }

  // ---------------- MICROPHONE TOGGLE ----------------
  Future<void> _handleMicrophoneToggle(bool value) async {
    if (value) {
      var status = await Permission.microphone.status;

      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        setState(() => _microphoneEnabled = false);
        _settingsService.setMicrophoneEnabled(false);
        return;
      }

      await MicListenService.startListening();
      await _sendMicCommand(true);

      setState(() => _microphoneEnabled = true);
      _settingsService.setMicrophoneEnabled(true);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 120);
      }

      debugPrint("🎤 Voice distress detection ENABLED");
    } else {
      MicListenService.stopListening();
      await _sendMicCommand(false);

      setState(() => _microphoneEnabled = false);
      _settingsService.setMicrophoneEnabled(false);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 80);
      }

      debugPrint("🛑 Voice distress detection DISABLED");
    }
  }

  // ---------------- PANIC GESTURE TOGGLE ----------------
  void _handlePanicGestureToggle(bool value) {
    setState(() => _panicGestureEnabled = value);
    _settingsService.setPanicGestureEnabled(value);

    if (value) {
      _startShakeDetection();
    } else {
      // 🔴 IMPORTANT FIX (your requested change)
      _shakeService.stopListeningCompletely();
      debugPrint("🛑 Panic gesture FULLY OFF");
    }
  }

  // ---------------- CENTRAL SHAKE START ----------------
  void _startShakeDetection() {
    _shakeService.startListening(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EmergencyHUD()),
      );
    });

    debugPrint("📡 Panic gesture ON");
  }

  // ---------------- LOGOUT ----------------
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Log Out",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      // 🔴 STOP EVERYTHING BEFORE LOGOUT
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Hub")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Shake Sensitivity"),
          Slider(
            min: 1,
            max: 10,
            value: sensitivity,
            onChanged: (v) {
              setState(() => sensitivity = v);
              _shakeService.setSensitivity(v);
            },
          ),

          const Divider(),

          SwitchListTile(
            title: const Text("Microphone Access"),
            subtitle: const Text("Enable voice-activated distress detection"),
            secondary: const Icon(Icons.mic),
            value: _microphoneEnabled,
            onChanged: _handleMicrophoneToggle,
          ),

          SwitchListTile(
            title: const Text("Panic Gesture Detection"),
            subtitle: const Text("Enable shake-gesture SOS trigger"),
            secondary: const Icon(Icons.vibration),
            value: _panicGestureEnabled,
            onChanged: _handlePanicGestureToggle,
          ),

          const Divider(),

          ListTile(
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.logout, color: Colors.red),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}

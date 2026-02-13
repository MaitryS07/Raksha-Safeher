import 'package:flutter/material.dart';

import '../services/mic_listen_service.dart';
import '../services/shake_service.dart';
import '../services/settings_service.dart';

import 'profile_screen.dart';
import 'guardians_screen.dart';
import 'incident_history_screen.dart';
import 'news_screen.dart';
import 'emergency_hud_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart';

import '../widgets/sos_button.dart';
import '../widgets/feature_title.dart';
import '../core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();
  final SettingsService _settingsService = SettingsService();

  // ================= EMERGENCY ACTION =================
  void _triggerEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyHUD()),
    );
  }

  // ================= APPLY LISTENERS BASED ON SETTINGS =================
  void _applyListeners() {
    // 🎤 MICROPHONE AI DETECTION
    if (_settingsService.isMicrophoneEnabled()) {
      MicListenService.startListening(onDistress: _triggerEmergency);
    } else {
      MicListenService.stopListening();
    }

    // 📳 SHAKE GESTURE DETECTION
    if (_settingsService.isPanicGestureEnabled()) {
      _shakeService.startListening(_triggerEmergency);
    } else {
      _shakeService.stopListening();
    }

    setState(() {}); // refresh mic banner
  }

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();
    _applyListeners();
  }

  @override
  void dispose() {
    MicListenService.stopListening();
    _shakeService.stopListening();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final micOn = _settingsService.isMicrophoneEnabled();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _applyListeners());
            },
          ),
        ],
      ),

      bottomNavigationBar: MicStatusBanner(active: micOn),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: SOSButton(onPressed: _triggerEmergency)),

                const SizedBox(height: 50),

                // Grid implementation
                Row(
                  children: [
                    Expanded(
                      child: FeatureTile(
                        icon: Icons.person,
                        title: "Profile",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FeatureTile(
                        icon: Icons.people,
                        title: "Guardians",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GuardiansScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Row 2: Incidents and Safety Map
                Row(
                  children: [
                    Expanded(
                      child: FeatureTile(
                        icon: Icons.history,
                        title: "Incidents",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IncidentHistoryScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FeatureTile(
                        icon: Icons.map,
                        title: "Safety Map",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= MIC STATUS FOOTER =================
class MicStatusBanner extends StatelessWidget {
  final bool active;
  const MicStatusBanner({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: active ? Colors.green.shade700 : Colors.red.shade700,
      child: Center(
        child: Text(
          active
              ? "🎤 Voice Distress Detection: ACTIVE"
              : "🛑 Microphone OFF — Distress detection disabled",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

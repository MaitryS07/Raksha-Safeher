import 'package:flutter/material.dart';

import '../services/shake_service.dart';
import '../services/mic_listen_service.dart'; // 🔥 REAL mic state

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

  bool _micActive = false;
  bool _panicActive = false;

  @override
  void initState() {
    super.initState();
    _loadStates(); // 🔥 get real runtime state
  }

  @override
  void dispose() {
    _shakeService.stopListeningCompletely();
    super.dispose();
  }

  // 🔄 Load REAL runtime states
  void _loadStates() {
    _micActive = MicListenService.micEnabled;
    _panicActive = _shakeService.isListening();

    if (mounted) setState(() {});
  }

  // 🎯 Panic gesture listener
  void _applyPanicListener() {
    if (_panicActive) {
      _shakeService.startListening(_triggerEmergency);
    } else {
      _shakeService.stopListeningCompletely();
    }
  }

  void _triggerEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyHUD()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              ).then((_) => _loadStates()); // 🔥 refresh after returning
            },
          ),
        ],
      ),

      // 🔥 STATUS BAR — NOW CORRECT
      bottomNavigationBar: Container(
        height: 46,
        color: _micActive ? Colors.green.shade700 : Colors.grey.shade800,
        child: Center(
          child: Text(
            _micActive
                ? "🎤 Distress Detection: ACTIVE"
                : "🛑 Distress Detection: OFF",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SOSButton(onPressed: _triggerEmergency),
              const SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FeatureTile(
                    icon: Icons.person,
                    title: "Profile",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                  FeatureTile(
                    icon: Icons.people,
                    title: "Guardians",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GuardiansScreen()),
                    ),
                  ),
                  FeatureTile(
                    icon: Icons.history,
                    title: "Incidents",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IncidentHistoryScreen()),
                    ),
                  ),
                  FeatureTile(
                    icon: Icons.article,
                    title: "Safety News",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewsScreen()),
                    ),
                  ),
                  FeatureTile(
                    icon: Icons.map,
                    title: "Safety Map",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

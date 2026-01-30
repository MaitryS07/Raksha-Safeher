import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

// NEW IMPORTS for background service & settings
import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/distress_service.dart'; // your distress service
import 'services/settings_service.dart'; // ← ADD THIS

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Required for plugins (permissions, shared prefs, background service)
  WidgetsFlutterBinding.ensureInitialized();

  // NEW: Initialize SharedPreferences for SettingsService
  await SettingsService().init();

  // NEW: Prepare the background distress listening service
  await initDistressService();

  // Optional: If you want distress listening ON by default (usually NOT — let user toggle it)
  // await startDistressListening();

  runApp(const RakshaApp());
}

class RakshaApp extends StatelessWidget {
  const RakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

import 'services/navigation_service.dart';
import 'services/emergency_service.dart';

final GlobalKey<NavigatorState> navigatorKey = NavigationService.navigatorKey;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sync SOS state on startup
  try {
    await EmergencyService().checkBackendState();
  } catch(e) {
    debugPrint("Startup Sync Error: $e");
  }
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

import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          _buildPage(context, "One-Tap SOS", "Press SOS to alert guardians", Icons.touch_app),
          _buildPage(context, "Shake Trigger", "Shake phone to activate emergency", Icons.vibration),
          _buildPage(context, "Silent Mode", "Power button trigger without noise", Icons.power_settings_new, isLast: true),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, String title, String desc, IconData icon, {bool isLast = false}) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          if (isLast)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Get Started"),
              ),
            )
        ],
      ),
    );
  }
}

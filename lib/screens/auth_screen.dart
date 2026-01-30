import 'package:flutter/material.dart';
import 'login_screen.dart';

/// AuthScreen serves as the entry point for authentication
/// Navigates to LoginScreen by default
/// Navigation flow: Signup → Login → HomeScreen
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate directly to LoginScreen
    // Users can navigate to SignupScreen from there
    return const LoginScreen();
  }
}

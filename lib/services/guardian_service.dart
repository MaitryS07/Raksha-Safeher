import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/guardian_model.dart';

class GuardianService {
  static final GuardianService _instance = GuardianService._internal();
  factory GuardianService() => _instance;
  GuardianService._internal();

  final List<Guardian> _guardians = [];

  // ← CHANGE THIS to match your backend address
  // Use 10.0.2.2 if testing on Android emulator
  // Use your computer's local IP if testing on physical device (same Wi-Fi)
  static const String _baseUrl = 'http://192.168.17.115:5000'; // ← your Flask server IP:port

  List<Guardian> getGuardians() {
    return List.unmodifiable(_guardians);
  }

  List<String> getGuardianPhones() {
    return _guardians.map((g) => g.phone).toList();
  }

  /// Adds guardian LOCALLY + sends to backend
  Future<bool> addGuardian(Guardian guardian) async {
    // 1. Try to add to backend first
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add_guardian'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guardian_phone': guardian.phone, // must be in +91xxxxxxxxxx format
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success → add locally too
        if (!_guardians.any((g) => g.phone == guardian.phone)) {
          _guardians.add(guardian);
        }
        print('Guardian added successfully: ${guardian.phone}');
        return true;
      } else {
        print('Backend rejected guardian: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error connecting to backend: $e');
      // Optional: still add locally if you want offline support
      // _guardians.add(guardian);
      return false;
    }
  }

  void removeGuardian(Guardian guardian) {
    _guardians.remove(guardian);
    // TODO: if you want, add DELETE call to backend later
  }

  void removeGuardianAt(int index) {
    if (index >= 0 && index < _guardians.length) {
      _guardians.removeAt(index);
    }
  }

  void clearGuardians() {
    _guardians.clear();
  }

  bool hasGuardians() {
    return _guardians.isNotEmpty;
  }

  // Optional: call this when app starts to show already added guardians
  // (if you later add /guardians GET endpoint in Flask)
  Future<void> loadGuardians() async {
    // implement if needed
  }
}
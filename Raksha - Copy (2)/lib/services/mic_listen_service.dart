import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

import 'emergency_service.dart';
import 'sqlite_service.dart';
import '../services/navigation_service.dart';
import '../screens/emergency_hud_screen.dart';

typedef DistressCallback = void Function();

class MicListenService {
  static final stt.SpeechToText _speech = stt.SpeechToText();

  static bool micEnabled = false;
  static DistressCallback? _onDistress;
  static Timer? _restartTimer;

  static int distressCount = 0;
  static const int distressLimit = 3;

  // 🔗 Replace with your laptop IP
  static const String aiUrl = "http://192.168.17.116:5000/check_distress";

  // ===============================
  // 🤖 SEND TEXT TO AI BACKEND
  // ===============================
  static Future<bool> checkWithAI(String text) async {
    try {
      final response = await http.post(
        Uri.parse(aiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      final data = jsonDecode(response.body);
      return data["result"] == "DISTRESS";
    } catch (e) {
      debugPrint("❌ AI request failed: $e");
      return false;
    }
  }

  // ===============================
  // 🎤 START LISTENING
  // ===============================
  static Future<void> startListening({DistressCallback? onDistress}) async {
    if (micEnabled) return;

    _onDistress = onDistress;
    bool available = false;

    try {
      // Initialize only if not already initialized
      if (!_speech.isAvailable) {
        available = await _speech.initialize(
          onStatus: (status) {
            debugPrint("🎙 Speech status: $status");
            if ((status == "done" || status == "notListening") && micEnabled) {
              // Auto-restart if it stops unexpectedly
              _restartListening();
            }
          },
          onError: (error) {
            debugPrint("❌ Speech error: ${error.errorMsg}");
            // Restart on error (e.g. no match found)
            if (micEnabled) {
               _restartListening();
            }
          },
        );
      } else {
        available = true;
      }

      if (!available) {
        debugPrint("❌ Speech recognition not available");
        micEnabled = false;
        return;
      }

      micEnabled = true;
      distressCount = 0;
      debugPrint("🎤 AI Voice distress detection STARTED");
      
      _listen();

    } catch (e) {
      debugPrint("🔥 Speech initialize FAILED: $e");
      micEnabled = false;
    }
  }
  
  static void _restartListening() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 1000), () {
      if (micEnabled && !_speech.isListening) {
         debugPrint("🔄 Restarting listener...");
         _listen();
      }
    });
  }

  static void _listen() {
    _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false, // Don't stop on minor errors
      onResult: (result) async {
        final text = result.recognizedWords.toLowerCase().trim();
        if (text.isEmpty) return;

        debugPrint("🎙 Heard: $text");

        final isDistress = await checkWithAI(text);

        if (isDistress) {
          distressCount++;
          debugPrint("⚠️ AI Distress count $distressCount / $distressLimit");
        } else {
          distressCount = 0;
        }

        if (distressCount >= distressLimit) {
          distressCount = 0;

          await SQLiteService.logIncident(
            "SOS triggered by AI voice detection",
          );

          // Open Emergency HUD (Dark Theme)
          // Note: EmergencyHUD calls activateEmergency() internally on init
          NavigationService.navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const EmergencyHUD()),
          );
          
          _onDistress?.call();
        }
      },
    );
  }

  // ===============================
  // 🛑 STOP LISTENING
  // ===============================
  static void stopListening() {
    if (!micEnabled) return;

    micEnabled = false;
    distressCount = 0;
    _onDistress = null;
    _restartTimer?.cancel();

    _speech.stop();
    debugPrint("🛑 Voice detection STOPPED");
  }
}

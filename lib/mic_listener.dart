import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'services/api_service.dart';

class MicListenerPage extends StatefulWidget {
  const MicListenerPage({super.key});

  @override
  State<MicListenerPage> createState() => _MicListenerPageState();
}

class _MicListenerPageState extends State<MicListenerPage> {
  final stt.SpeechToText sttEngine = stt.SpeechToText();

  bool listening = false;
  int distressCount = 0;
  final int distressLimit = 3;

  Future<void> startListening() async {
    bool available = await sttEngine.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );

    if (!available) return;

    setState(() => listening = true);

    sttEngine.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      onResult: (result) async {
        final text = result.recognizedWords.toLowerCase();
        debugPrint("🎙 Heard: $text");

        await ApiService.sendTranscript(text);

        if (text.contains("help") ||
            text.contains("save me") ||
            text.contains("mujhe bachao") ||
            text.contains("koi mera picha kar raha hai")) {
          distressCount++;
        } else {
          distressCount = 0;
        }

        if (distressCount >= distressLimit) {
          debugPrint("🚨 DISTRESS LEVEL 3 — Triggering SOS");
          await ApiService.triggerSOS();
          distressCount = 0;
        }

        startListening(); // restart continuous listening
      },
    );
  }

  @override
  void initState() {
    super.initState();
    startListening();
  }

  @override
  void dispose() {
    sttEngine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          listening ? "🎤 Listening..." : "Tap to Start",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

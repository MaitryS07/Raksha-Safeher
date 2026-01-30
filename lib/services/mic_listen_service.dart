import 'dart:io';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'emergency_service.dart';
import 'sqlite_service.dart';

class MicListenService {
  static final AudioRecorder _recorder = AudioRecorder();

  static bool micEnabled = false;
  static bool _isStarting = false;

  // 🔁 Start continuous background listening safely
  static Future<void> startListening() async {
    if (micEnabled || _isStarting) return; // 🛑 prevents double start
    _isStarting = true;
    micEnabled = true;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_chunk.wav';

    print("🎤 Background voice monitoring STARTED");

    try {
      while (micEnabled) {
        if (!await _recorder.hasPermission()) {
          print("❌ Mic permission missing");
          break;
        }

        // 🎙 Record short audio chunk
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            bitRate: 128000,
          ),
          path: path,
        );

        await Future.delayed(const Duration(seconds: 4));
        await _recorder.stop();

        // 📡 Send audio to backend
        await _sendAudioToServer(File(path));
      }
    } catch (e) {
      print("🔥 Mic service error: $e");
    }

    _isStarting = false;
    micEnabled = false;
  }

  // 🛑 Stop safely
  static Future<void> stopListening() async {
    if (!micEnabled) return;

    micEnabled = false;
    try {
      await _recorder.stop();
    } catch (_) {}
    print("🛑 Background voice monitoring STOPPED");
  }

  // 🌐 Send recorded audio to server
  static Future<void> _sendAudioToServer(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://YOUR_SERVER_IP:5000/detect'), // change IP
      );

      request.files.add(await http.MultipartFile.fromPath('audio', file.path));
      request.fields['device_id'] = "raksha_user"; // required for server counter

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseText = await response.stream.bytesToString();
        final data = jsonDecode(responseText);

        if (data['trigger'] == true) {
          print("🚨 DISTRESS CONFIRMED (3x) FROM SERVER");

          await SQLiteService.logIncident(
            "SOS triggered by background voice detection",
          );

          EmergencyService().activateEmergency();
        }
      }
    } catch (e) {
      print("🌐 Server communication error: $e");
    }
  }
}

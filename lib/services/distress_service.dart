// lib/services/distress_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

// Global state
int _distressCount = 0;
const int _threshold = 3;
const String _backendUrl = 'http://192.168.17.115:5000/detect_distress';
const Duration _chunkDuration = Duration(seconds: 30);

bool _shouldRun = true;

Future<void> initDistressService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'distress_channel',
      initialNotificationTitle: 'Safety Listening Active',
      initialNotificationContent: 'Continuous monitoring for distress keywords...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStart,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  _shouldRun = true;
  _distressCount = 0;

  service.on('stopService').listen((event) {
    _shouldRun = false;
  });

  final AudioRecorder record = AudioRecorder();
  final tempDir = await getTemporaryDirectory();

  while (_shouldRun) {
    try {
      if (!await record.hasPermission()) {
        print('Microphone permission lost');
        break;
      }

      final filePath = '${tempDir.path}/distress_audio.m4a';

      // ✅ Start recording (NEW API)
      await record.start(
        const RecordConfig(),
        path: filePath,
      );

      await Future.delayed(_chunkDuration);

      // ✅ Stop recording and get actual path
      final recordedPath = await record.stop();
      if (recordedPath == null) continue;

      // Send to backend
      final request =
          http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(
        await http.MultipartFile.fromPath('audio', recordedPath),
      );

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final responseBytes = await streamedResponse.stream.toBytes();
        final responseString = utf8.decode(responseBytes);
        final json = jsonDecode(responseString);

        if (json['status'] == 'DISTRESS') {
          _distressCount++;

          if (_distressCount >= _threshold) {
            await _triggerSOS();
            _distressCount = 0;
          }
        } else {
          _distressCount = 0;
        }
      }

      // Cleanup
      try {
        await File(recordedPath).delete();
      } catch (_) {}

    } catch (e) {
      print('Error in distress loop: $e');
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  print('Distress background service stopped');
}

Future<void> startDistressListening() async {
  final status = await Permission.microphone.request();
  if (status.isGranted) {
    final service = FlutterBackgroundService();
    await service.startService();
  }
}

Future<void> stopDistressListening() async {
  final service = FlutterBackgroundService();
  service.invoke('stopService');
  _distressCount = 0;
}

Future<void> _triggerSOS() async {
  try {
    await http.post(
      Uri.parse('http://192.168.17.115:5000/sos_trigger'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
  } catch (e) {
    print('Failed to trigger SOS: $e');
  }
}

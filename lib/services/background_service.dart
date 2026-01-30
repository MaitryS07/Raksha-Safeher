import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'mic_listen_service.dart';

class BackgroundMicService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        notificationChannelId: "raksha_mic_channel",
        initialNotificationTitle: "Raksha Safety Active",
        initialNotificationContent: "Voice monitoring ready",
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }
}

@pragma("vm:entry-point")
void onStart(ServiceInstance service) async {
  bool micRunning = false;

  if (service is AndroidServiceInstance) {
    // Promote ONCE only here
    service.setForegroundNotificationInfo(
      title: "Raksha Safety Active",
      content: "Waiting for voice activation",
    );

    service.setAsForegroundService();
  }

  // MIC ON
  service.on("mic_on").listen((_) async {
    if (micRunning) return;
    micRunning = true;

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Raksha — Listening",
        content: "Microphone active",
      );
      // ❌ DO NOT call setAsForegroundService again
    }

    await MicListenService.startListening();
  });

  // MIC OFF
  service.on("mic_off").listen((_) async {
    if (!micRunning) return;
    micRunning = false;

    await MicListenService.stopListening();

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Raksha",
        content: "Voice detection paused",
      );
    }
  });

  // FULL STOP
  service.on("stop_service").listen((_) async {
    await MicListenService.stopListening();
    service.stopSelf();
  });
}

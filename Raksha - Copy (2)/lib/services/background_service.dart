import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'mic_listen_service.dart';

class BackgroundMicService {
  static Future<void> init() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,

        // 🔴 CRITICAL — must exist BEFORE setAsForegroundService()
        notificationChannelId: "raksha_mic_channel",
        initialNotificationTitle: "Raksha Safety Active",
        initialNotificationContent: "Listening for distress voice commands",

        // 🔴 CRITICAL — prevents Android crash
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }
}

@pragma("vm:entry-point")
void onStart(ServiceInstance service) async {
  // -------------------------
  // MAKE SERVICE FOREGROUND
  // -------------------------
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    // First valid notification — Android requires this
    service.setForegroundNotificationInfo(
      title: "Raksha Safety Active",
      content: "Voice distress detection running",
    );
  }

  // -------------------------
  // MIC ON
  // -------------------------
  service.on("mic_on").listen((_) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Raksha — Listening",
        content: "Microphone active",
      );
    }

    await MicListenService.startListening();
  });

  // -------------------------
  // MIC OFF
  // -------------------------
  service.on("mic_off").listen((_) {
    MicListenService.stopListening();

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Raksha",
        content: "Voice detection stopped",
      );
      service.stopSelf();
    }
  });
}

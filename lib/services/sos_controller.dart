import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'sos_api.dart';

class SosController {
  static Timer? _locationTimer;

  static Future<String> _getLocationUrl() async {
    final pos = await Geolocator.getCurrentPosition();
    return "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
  }

  static Future<void> startSOS() async {
    final loc = await _getLocationUrl();

    // Start SOS in backend
    await SosApi.triggerSOS(loc);

    // Send live GPS every 5 sec
    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      final live = await _getLocationUrl();
      await SosApi.sendLocation(live);
    });
  }

  static void stopSOS() {
    _locationTimer?.cancel();
  }
}

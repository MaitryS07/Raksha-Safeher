import 'package:flutter/material.dart';
import 'dart:async';
import '../core/constants.dart';
import '../services/location_service.dart';
import '../core/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  Timer? _locationTracker;
  bool _isTracking = false;
  Map<String, double>? _currentLocation;
  String? _locationLink;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      final link = await _locationService.getLocationLink();
      setState(() {
        _currentLocation = location;
        _locationLink = link;
      });
    } catch (e) {
      if (mounted) {
        Utils.showSnackBar(context, "Failed to get location: $e");
      }
    }
  }

  void _startLiveTracking() {
    if (_isTracking) {
      _stopLiveTracking();
      return;
    }

    setState(() => _isTracking = true);
    _locationTracker = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _getCurrentLocation();
    });
  }

  void _stopLiveTracking() {
    _locationTracker?.cancel();
    setState(() => _isTracking = false);
  }

  Future<void> _openInMaps() async {
    if (_locationLink != null) {
      final uri = Uri.parse(_locationLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Utils.showSnackBar(context, "Could not open maps");
      }
    }
  }

  Future<void> _suggestSafeRoute() async {
    if (_currentLocation == null) {
      Utils.showSnackBar(context, "Location not available");
      return;
    }

    // Simulate safe route suggestion
    // In real implementation, this would use Google Maps Directions API
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Safe Route Suggestion"),
        content: const Text(
          "Based on your location, here are the safest routes:\n\n"
          "1. Main Street (Well-lit, High traffic)\n"
          "2. Park Avenue (CCTV cameras)\n"
          "3. Market Road (Police patrol area)\n\n"
          "Avoid: Dark alleys and isolated areas",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openInMaps();
            },
            child: const Text("Open in Maps"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopLiveTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Map"),
      ),
      body: Column(
        children: [
          // Map placeholder
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 80,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Live Location Tracking",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        if (_currentLocation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Lat: ${_currentLocation!['latitude']!.toStringAsFixed(4)}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "Lng: ${_currentLocation!['longitude']!.toStringAsFixed(4)}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                        if (_isTracking) ...[
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Tracking Active",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Safe zones indicator
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Safe Zone",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text("Get Location"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startLiveTracking,
                        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                        label: Text(_isTracking ? "Stop Tracking" : "Start Tracking"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _isTracking ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _suggestSafeRoute,
                    icon: const Icon(Icons.route),
                    label: const Text("Suggest Safe Route"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  ),
                ),
                if (_locationLink != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openInMaps,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Open in Google Maps"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MicStatusBanner extends StatelessWidget {
  final bool active;

  const MicStatusBanner({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.green.shade700,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "Listening for distress…",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

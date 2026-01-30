import 'package:flutter/material.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SOSButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 160,
        width: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Colors.purple, Colors.deepPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "SOS",
            style: TextStyle(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

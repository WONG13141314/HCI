// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10b981), Color(0xFF059669)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 130))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12),
                     duration: 1750.ms)
              .rotate(begin: 0, end: 0.033),
          const SizedBox(height: 28),
          const Text('WildTrack AR',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          const Text('Genting Nature Adventures',
              style: TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 50),
          // Loading bar
          SizedBox(
            width: 270,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

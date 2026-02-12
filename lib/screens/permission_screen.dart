// lib/screens/permission_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;
  const PermissionScreen({super.key, required this.onGranted});

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
      padding: const EdgeInsets.all(45),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📸', style: TextStyle(fontSize: 110)),
          const SizedBox(height: 32),
          const Text('Camera Access',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          const Text(
            'Enable camera to detect wildlife in AR.\nMove your phone around to discover species!',
            style: TextStyle(fontSize: 18, color: Colors.white, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGranted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32)),
                textStyle: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: const Text('Enable Camera'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  context.read<GameController>().skipToGame(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54, width: 3),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                textStyle: const TextStyle(fontSize: 17),
              ),
              child: const Text('Use Forest View'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tutorial screen ──────────────────────────────────────────────────────────

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.96),
      padding: const EdgeInsets.all(45),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 110)),
          const SizedBox(height: 32),
          const Text('How It Works',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          const Text(
            'Slowly pan your camera around.\n\n'
            'Wildlife will appear somewhere nearby — pan until you find it.\n\n'
            'Centre it in the green viewfinder, then tap SCAN to capture!',
            style: TextStyle(fontSize: 17, color: Colors.white, height: 1.75),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<GameController>().startGame(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32)),
                textStyle: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: const Text('Start Hunting! 🌿'),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'game/game_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/ar_game_screen.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Get available cameras
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera discovery error: $e');
  }

  runApp(const WildTrackApp());
}

class WildTrackApp extends StatelessWidget {
  const WildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: MaterialApp(
        title: 'WildTrack AR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10b981),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AppRouter(),
      ),
    );
  }
}

// ─── Router — listens to GameController.screen ────────────────────────────────

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _cameraRequested = false;

  Future<void> _requestCamera() async {
    setState(() => _cameraRequested = true);
    // Camera plugin handles permission request on first availableCameras() call.
    // If cameras were already found at launch, go straight to tutorial.
    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        debugPrint('Camera permission error: $e');
      }
    }
    if (mounted) context.read<GameController>().screen = GameScreen.tutorial;
    if (mounted) context.read<GameController>().notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, ctrl, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildScreen(ctrl),
        );
      },
    );
  }

  Widget _buildScreen(GameController ctrl) {
    switch (ctrl.screen) {
      case GameScreen.splash:
        return const SplashScreen(key: ValueKey('splash'));

      case GameScreen.permission:
        return PermissionScreen(
          key: const ValueKey('permission'),
          onGranted: _requestCamera,
        );

      case GameScreen.tutorial:
        return const _TutorialWrapper(key: ValueKey('tutorial'));

      case GameScreen.playing:
        return ArGameScreen(
          key: const ValueKey('game'),
          cameras: _cameras,
        );
    }
  }
}

// Small wrapper so tutorial can call startGame on controller
class _TutorialWrapper extends StatelessWidget {
  const _TutorialWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Import tutorial from permission_screen file
    return const _TutorialScreenEmbed();
  }
}

class _TutorialScreenEmbed extends StatelessWidget {
  const _TutorialScreenEmbed();

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
              style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'game/game_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/ar_game_screen.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Get available cameras
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera discovery error: $e');
  }

  runApp(const WildTrackApp());
}

class WildTrackApp extends StatelessWidget {
  const WildTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: MaterialApp(
        title: 'WildTrack AR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10b981),
            brightness: Brightness.dark,
            primary: const Color(0xFF10b981),
            secondary: const Color(0xFF059669),
            surface: const Color(0xFF1a1a1a),
            background: const Color(0xFF0a0a0a),
          ),
          // CHANGED: Using default font instead of Google Fonts
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
            fontFamily: 'Roboto', // System font
          ),
          cardTheme: CardTheme(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              // CHANGED: Using TextStyle instead of GoogleFonts
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _cameraRequested = false;

  Future<void> _requestCamera() async {
    if (_cameraRequested) return;
    
    setState(() => _cameraRequested = true);
    
    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        debugPrint('Camera permission error: $e');
      }
    }
    
    if (mounted) {
      context.read<GameController>().screen = GameScreen.tutorial;
      context.read<GameController>().notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, ctrl, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
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
        return TutorialScreen(
          key: const ValueKey('tutorial'),
          onStart: () => context.read<GameController>().startGame(),
        );

      case GameScreen.playing:
        return ArGameScreen(
          key: const ValueKey('game'),
          cameras: _cameras,
        );
    }
  }
}
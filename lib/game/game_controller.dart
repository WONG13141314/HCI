import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/species.dart';

class WildlifeInstance {
  final Species species;
  final double spawnYaw;
  final double spawnPitch;
  final DateTime spawnTime;

  WildlifeInstance({
    required this.species,
    required this.spawnYaw,
    required this.spawnPitch,
  }) : spawnTime = DateTime.now();
}

enum GameScreen { splash, permission, tutorial, playing }

class GameController extends ChangeNotifier {
  // Screen state
  GameScreen screen = GameScreen.splash;

  // Game stats
  int points = 0;
  List<int> discoveredIds = [];

  // Current wildlife
  WildlifeInstance? currentWildlife;
  bool targetLocked = false;

  // Gyroscope / orientation state
  double currentYaw = 0;
  double currentPitch = 0;

  // Motion accumulator for spawning
  double _motionAccum = 0;
  double _lastMotionUpdate = 0;

  // Status message
  String statusMessage = '';
  bool statusVisible = false;
  Timer? _statusTimer;

  // Internal
  StreamSubscription? _gyroSub;
  Timer? _spawnTimer;
  final Random _rng = Random();

  // Field of view
  static const double hFov = 60.0;
  static const double vFov = 45.0;

  // Smoothing for better AR experience
  static const double _smoothingFactor = 0.7;
  double _smoothedYaw = 0;
  double _smoothedPitch = 0;

  GameController() {
    _loadProgress();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (screen == GameScreen.splash) {
        screen = GameScreen.permission;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      discoveredIds = (prefs.getStringList('discovered') ?? [])
          .map((e) => int.tryParse(e) ?? 0)
          .where((id) => id > 0)
          .toList();
      points = prefs.getInt('points') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'discovered',
        discoveredIds.map((e) => e.toString()).toList(),
      );
      await prefs.setInt('points', points);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  void startGame() {
    screen = GameScreen.playing;
    _startGyroscope();
    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _checkMotion(),
    );
    showStatus('🌿 Move your camera slowly to discover wildlife...');
    notifyListeners();
  }

  void skipToGame() {
    screen = GameScreen.playing;
    _startGyroscope();
    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _checkMotion(),
    );
    showStatus('🌿 Using forest view mode');
    notifyListeners();
  }

  void _startGyroscope() {
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((GyroscopeEvent e) {
      const dt = 0.02; // ~50Hz

      // Calculate angular changes
      final dYaw = -e.y * dt * (180 / pi);
      final dPitch = -e.x * dt * (180 / pi);

      // Update raw values
      currentYaw += dYaw;
      currentPitch = (currentPitch + dPitch).clamp(-70.0, 70.0);

      // Apply smoothing for better visual experience
      _smoothedYaw = _smoothedYaw * _smoothingFactor + 
                     currentYaw * (1 - _smoothingFactor);
      _smoothedPitch = _smoothedPitch * _smoothingFactor + 
                       currentPitch * (1 - _smoothingFactor);

      // Accumulate movement magnitude
      final motionMagnitude = dYaw.abs() + dPitch.abs();
      _motionAccum += motionMagnitude;
      _lastMotionUpdate = DateTime.now().millisecondsSinceEpoch.toDouble();

      notifyListeners();
    });
  }

  void _checkMotion() {
    if (currentWildlife != null) {
      _motionAccum = 0;
      return;
    }

    // Decay motion over time
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final timeSinceLastMotion = (now - _lastMotionUpdate) / 1000;
    if (timeSinceLastMotion > 0.5) {
      _motionAccum = (_motionAccum * 0.9).clamp(0, double.infinity);
    }

    // Spawn if enough motion accumulated
    if (_motionAccum > 2.0) {
      _motionAccum = 0;
      if (_rng.nextDouble() < 0.6) {
        _spawnWildlife();
      }
    }
  }

  void _spawnWildlife() {
    final available = allSpecies
        .where((s) => !discoveredIds.contains(s.id))
        .toList();

    if (available.isEmpty) {
      // All discovered - spawn random one
      final sp = allSpecies[_rng.nextInt(allSpecies.length)];
      showStatus('${sp.icon} ${sp.name} appeared again!');
      
      final yawOffset = (_rng.nextDouble() * hFov * 2.5) - hFov * 1.25;
      final pitchOffset = (_rng.nextDouble() * vFov * 1.5) - vFov * 0.75;

      currentWildlife = WildlifeInstance(
        species: sp,
        spawnYaw: currentYaw + yawOffset,
        spawnPitch: currentPitch + pitchOffset,
      );
      targetLocked = false;
      notifyListeners();
      return;
    }

    final selected = available[_rng.nextInt(available.length)];

    // Place animal at random offset from current camera direction
    double yawOffset, pitchOffset;
    int attempts = 0;
    do {
      yawOffset = (_rng.nextDouble() * hFov * 2.5) - hFov * 1.25;
      pitchOffset = (_rng.nextDouble() * vFov * 1.5) - vFov * 0.75;
      attempts++;
    } while (attempts < 20 && 
             yawOffset.abs() < 12 && 
             pitchOffset.abs() < 8);

    currentWildlife = WildlifeInstance(
      species: selected,
      spawnYaw: currentYaw + yawOffset,
      spawnPitch: currentPitch + pitchOffset,
    );

    targetLocked = false;
    showStatus('${selected.icon} ${selected.name} spotted nearby!');
    notifyListeners();
  }

  Offset? wildlifeScreenPosition(Size screenSize) {
    if (currentWildlife == null) return null;

    // Use smoothed values for smoother on-screen movement
    final dYaw = currentWildlife!.spawnYaw - _smoothedYaw;
    final dPitch = currentWildlife!.spawnPitch - _smoothedPitch;

    // Map angle to screen fraction
    final xFrac = 0.5 + (dYaw / hFov);
    final yFrac = 0.5 + (dPitch / vFov);

    return Offset(
      (xFrac * screenSize.width).clamp(-150, screenSize.width + 150),
      (yFrac * screenSize.height).clamp(-150, screenSize.height + 150),
    );
  }

  void checkTargeting(Offset wildlifePos, Rect viewfinderRect) {
    final inTarget = viewfinderRect.contains(wildlifePos);

    if (inTarget != targetLocked) {
      targetLocked = inTarget;
      notifyListeners();
    }
  }

  bool scanTarget() {
    if (!targetLocked || currentWildlife == null) return false;

    final sp = currentWildlife!.species;
    final isNew = !discoveredIds.contains(sp.id);

    if (isNew) {
      discoveredIds.add(sp.id);
      points += sp.points;
      _saveProgress();
    }

    currentWildlife = null;
    targetLocked = false;
    notifyListeners();
    return isNew;
  }

  void showStatus(String msg) {
    statusMessage = msg;
    statusVisible = true;
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(milliseconds: 3000), () {
      statusVisible = false;
      notifyListeners();
    });
    notifyListeners();
  }

  // Reset game progress
  Future<void> resetProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('discovered');
      await prefs.remove('points');
      discoveredIds.clear();
      points = 0;
      currentWildlife = null;
      targetLocked = false;
      notifyListeners();
      showStatus('🔄 Progress reset!');
    } catch (e) {
      debugPrint('Error resetting progress: $e');
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _spawnTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}
// lib/game/game_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/species.dart';

// ─── Wildlife instance positioned in "world space" via gyroscope angles ──────

class WildlifeInstance {
  final Species species;

  /// Yaw offset (horizontal) from when the species spawned, in degrees.
  /// The animal is "anchored" to a heading — as you pan the camera,
  /// the animal moves on screen relative to where you're pointing.
  final double spawnYaw;

  /// Pitch offset (vertical), in degrees.
  final double spawnPitch;

  WildlifeInstance({
    required this.species,
    required this.spawnYaw,
    required this.spawnPitch,
  });
}

// ─── Game state ───────────────────────────────────────────────────────────────

enum GameScreen { splash, permission, tutorial, playing }

class GameController extends ChangeNotifier {
  // ── Screen state ────────────────────────────────────────────────────────────
  GameScreen screen = GameScreen.splash;

  // ── Stats ───────────────────────────────────────────────────────────────────
  int points = 0;
  List<int> discoveredIds = [];

  // ── Current wildlife ────────────────────────────────────────────────────────
  WildlifeInstance? currentWildlife;
  bool targetLocked = false;

  // ── Gyroscope / orientation state ───────────────────────────────────────────
  /// Current integrated yaw (horizontal pan) in degrees.
  double currentYaw   = 0;
  /// Current integrated pitch (vertical tilt) in degrees.
  double currentPitch = 0;

  // ── Motion accumulator for spawning ─────────────────────────────────────────
  double _motionAccum = 0;
  double _prevGyrX = 0, _prevGyrY = 0;

  // ── Status message ───────────────────────────────────────────────────────────
  String statusMessage = '';
  bool statusVisible = false;
  Timer? _statusTimer;

  // ── Internal ─────────────────────────────────────────────────────────────────
  StreamSubscription? _gyroSub;
  Timer? _spawnTimer;
  final Random _rng = Random();

  // ── Field of view used for mapping gyro angle → screen pixel ────────────────
  /// Horizontal FOV in degrees (typical phone camera ~60°)
  static const double hFov = 60.0;
  /// Vertical FOV in degrees
  static const double vFov = 45.0;

  // ─── Init ──────────────────────────────────────────────────────────────────

  GameController() {
    _loadProgress();
    // Auto-advance splash after 2.6 s
    Future.delayed(const Duration(milliseconds: 2600), () {
      screen = GameScreen.permission;
      notifyListeners();
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    discoveredIds = (prefs.getStringList('discovered') ?? [])
        .map(int.parse)
        .toList();
    points = prefs.getInt('points') ?? 0;
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('discovered', discoveredIds.map((e) => '$e').toList());
    await prefs.setInt('points', points);
  }

  // ─── Screen transitions ────────────────────────────────────────────────────

  void startGame() {
    screen = GameScreen.playing;
    _startGyroscope();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 300), (_) => _checkMotion());
    showStatus('📱 Move your camera around slowly...');
    notifyListeners();
  }

  void skipToGame() {
    screen = GameScreen.playing;
    _startGyroscope();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 300), (_) => _checkMotion());
    showStatus('📱 Move your camera around slowly...');
    notifyListeners();
  }

  // ─── Gyroscope integration ─────────────────────────────────────────────────

  void _startGyroscope() {
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((GyroscopeEvent e) {
      // e.x = pitch rate (rad/s), e.y = yaw rate (rad/s), e.z = roll rate
      // Integrate at ~50Hz (gameInterval ≈ 20ms)
      const dt = 0.02;

      final dYaw   = e.y * dt * (180 / pi);  // rad → degrees
      final dPitch = e.x * dt * (180 / pi);

      currentYaw   += dYaw;
      currentPitch  = (currentPitch + dPitch).clamp(-60.0, 60.0);

      // Accumulate movement magnitude for spawn trigger
      _motionAccum += (dYaw.abs() + dPitch.abs());

      notifyListeners();
    });
  }

  // ─── Motion → spawn check ──────────────────────────────────────────────────

  void _checkMotion() {
    if (currentWildlife != null) {
      _motionAccum = 0;
      return;
    }

    if (_motionAccum > 1.5) {
      _motionAccum = 0;
      if (_rng.nextDouble() < 0.55) _spawnWildlife();
    } else {
      _motionAccum = (_motionAccum - 0.5).clamp(0, double.infinity);
    }
  }

  // ─── Spawn wildlife ────────────────────────────────────────────────────────

  void _spawnWildlife() {
    final available = allSpecies
        .where((s) => !discoveredIds.contains(s.id))
        .toList();

    if (available.isEmpty) {
      showStatus('🎉 All species discovered!');
      return;
    }

    final selected = available[_rng.nextInt(available.length)];

    // Place animal at a random angular offset from current camera direction.
    // Offset is within ±(FOV*0.8) so it's just off-screen or near edge.
    // Player must pan to bring it into the center viewfinder zone.
    double yawOffset, pitchOffset;
    int attempts = 0;
    do {
      // Random offset in range [-FOV*1.5 .. +FOV*1.5], excluding center ±15°
      yawOffset   = (_rng.nextDouble() * hFov * 3) - hFov * 1.5;
      pitchOffset = (_rng.nextDouble() * vFov * 2) - vFov;
      attempts++;
    } while (attempts < 30 && yawOffset.abs() < 15 && pitchOffset.abs() < 10);

    currentWildlife = WildlifeInstance(
      species: selected,
      spawnYaw:   currentYaw   + yawOffset,
      spawnPitch: currentPitch + pitchOffset,
    );

    targetLocked = false;
    showStatus('${selected.icon} ${selected.name} appeared! Pan to find it!');
    notifyListeners();
  }

  // ─── Compute screen position of wildlife ──────────────────────────────────
  /// Returns normalised [0..1] x,y position on screen for the current wildlife,
  /// based on how far the camera has panned from the spawn heading.
  /// Returns null if no wildlife active.
  Offset? wildlifeScreenPosition(Size screenSize) {
    if (currentWildlife == null) return null;

    // Angular difference between current camera direction and spawn direction
    final dYaw   = currentWildlife!.spawnYaw   - currentYaw;
    final dPitch = currentWildlife!.spawnPitch - currentPitch;

    // Map angle → screen fraction
    // When dYaw == 0, animal is centred horizontally
    final xFrac = 0.5 + (dYaw   / hFov);
    final yFrac = 0.5 + (dPitch / vFov);

    return Offset(
      (xFrac * screenSize.width).clamp(-100, screenSize.width  + 100),
      (yFrac * screenSize.height).clamp(-100, screenSize.height + 100),
    );
  }

  // ─── Check if wildlife is in viewfinder ───────────────────────────────────
  void checkTargeting(Offset wildlifePos, Rect viewfinderRect) {
    final inTarget = viewfinderRect.contains(wildlifePos);

    if (inTarget != targetLocked) {
      targetLocked = inTarget;
      notifyListeners();
    }
  }

  // ─── Scan / capture ───────────────────────────────────────────────────────
  bool scanTarget() {
    if (!targetLocked || currentWildlife == null) return false;

    final sp    = currentWildlife!.species;
    final isNew = !discoveredIds.contains(sp.id);

    if (isNew) {
      discoveredIds.add(sp.id);
      points += sp.points;
      _saveProgress();
    }

    currentWildlife = null;
    targetLocked    = false;
    notifyListeners();
    return isNew;
  }

  // ─── Status message ───────────────────────────────────────────────────────
  void showStatus(String msg) {
    statusMessage = msg;
    statusVisible = true;
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(milliseconds: 2800), () {
      statusVisible = false;
      notifyListeners();
    });
    notifyListeners();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _gyroSub?.cancel();
    _spawnTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}

// lib/screens/ar_game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/game_controller.dart';
import '../models/species.dart';
import '../widgets/ar_viewfinder.dart';
import '../widgets/wildlife_sprite.dart';
import '../widgets/species_modal.dart';

class ArGameScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ArGameScreen({super.key, required this.cameras});

  @override
  State<ArGameScreen> createState() => _ArGameScreenState();
}

class _ArGameScreenState extends State<ArGameScreen> {
  CameraController? _cameraCtrl;
  bool _cameraReady = false;

  // Key to measure viewfinder bounds
  final GlobalKey _viewfinderKey = GlobalKey();

  // Modal state
  Species? _modalSpecies;
  bool _modalIsNew = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;

    // Prefer rear camera
    final cam = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _cameraCtrl = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    super.dispose();
  }

  // ─── Get viewfinder rect in screen coordinates ─────────────────────────────

  Rect? _getViewfinderRect() {
    final ctx = _viewfinderKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size;
  }

  // ─── Vibrate helper ────────────────────────────────────────────────────────

  Future<void> _vibrate(List<int> pattern) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  // ─── Scan button pressed ───────────────────────────────────────────────────

  void _onScan() {
    final ctrl = context.read<GameController>();
    if (!ctrl.targetLocked || ctrl.currentWildlife == null) {
      ctrl.showStatus('🎯 Centre wildlife in viewfinder first!');
      _vibrate([100]);
      return;
    }

    final sp    = ctrl.currentWildlife!.species;
    final isNew = ctrl.scanTarget();
    _vibrate([200, 100, 200]);

    setState(() {
      _modalSpecies = sp;
      _modalIsNew   = isNew;
    });
  }

  void _closeModal() {
    setState(() => _modalSpecies = null);
  }

  // ─── Collection dialog ─────────────────────────────────────────────────────

  void _showCollection() {
    final ctrl = context.read<GameController>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📚 Collection'),
        content: ctrl.discoveredIds.isEmpty
            ? const Text('No species yet!\n\nMove camera to find wildlife.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ctrl.discoveredIds.map((id) {
                  final sp = allSpecies.firstWhere((s) => s.id == id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${sp.icon} ${sp.name}',
                        style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  // ─── Help dialog ──────────────────────────────────────────────────────────

  void _showHelp() {
    final ctrl = context.read<GameController>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ℹ️ How to Play'),
        content: Text(
          '1. Pan your camera slowly\n'
          '2. Wildlife will appear nearby\n'
          '3. Pan until it enters the green viewfinder\n'
          '4. Tap SCAN when locked (turns amber)\n\n'
          'Progress: ${ctrl.discoveredIds.length}/6',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          )
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, ctrl, _) {
        final size = MediaQuery.of(context).size;

        // Compute wildlife screen position
        final wildlifePos = ctrl.wildlifeScreenPosition(size);

        // Live targeting check every frame
        if (wildlifePos != null && ctrl.currentWildlife != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final vfRect = _getViewfinderRect();
            if (vfRect != null) {
              ctrl.checkTargeting(wildlifePos, vfRect);
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Camera feed / forest fallback ───────────────────────────
              if (_cameraReady && _cameraCtrl != null)
                Positioned.fill(child: CameraPreview(_cameraCtrl!))
              else
                Positioned.fill(child: _ForestFallback()),

              // ── Wildlife sprite (tracks gyro position) ───────────────────
              if (wildlifePos != null && ctrl.currentWildlife != null)
                WildlifeSprite(
                  key: ValueKey(ctrl.currentWildlife!.species.id),
                  species: ctrl.currentWildlife!.species,
                  position: wildlifePos,
                  targeted: ctrl.targetLocked,
                ),

              // ── AR Viewfinder (always centred) ──────────────────────────
              Center(
                child: ArViewfinder(
                  locked: ctrl.targetLocked,
                  viewfinderKey: _viewfinderKey,
                ),
              ),

              // ── Instruction hint ─────────────────────────────────────────
              if (ctrl.currentWildlife == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 180),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 25),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: const Color(0xFF10b981).withOpacity(0.7),
                            width: 3),
                      ),
                      child: const Text(
                        '📱 Pan your camera slowly...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // ── Top HUD ──────────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      22,
                      MediaQuery.of(context).padding.top + 22,
                      22,
                      0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      _StatBox(icon: '🏆', value: '${ctrl.points}'),
                      const SizedBox(width: 12),
                      _StatBox(
                          icon: '📍',
                          value: '${ctrl.discoveredIds.length}/6'),
                    ],
                  ),
                ),
              ),

              // ── Status message ────────────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 110,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: ctrl.statusVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: const Color(0xFF10b981).withOpacity(0.7),
                            width: 2),
                      ),
                      child: Text(
                        ctrl.statusMessage,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom controls ───────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      25,
                      35,
                      25,
                      MediaQuery.of(context).padding.bottom + 35),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlBtn(
                        icon: 'ℹ️',
                        onTap: _showHelp,
                      ),
                      const SizedBox(width: 50),
                      _ScanButton(
                        locked: ctrl.targetLocked,
                        onTap: _onScan,
                      ),
                      const SizedBox(width: 50),
                      _ControlBtn(
                        icon: '📚',
                        onTap: _showCollection,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Species modal (full screen overlay) ──────────────────────
              if (_modalSpecies != null)
                SpeciesModal(
                  species: _modalSpecies!,
                  isNew: _modalIsNew,
                  onClose: _closeModal,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── HUD stat box ─────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String icon, value;
  const _StatBox({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF10b981).withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 18)],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Control button ───────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 25)],
        ),
        child: Center(
          child: Text(icon, style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}

// ─── Scan button ─────────────────────────────────────────────────────────────

class _ScanButton extends StatelessWidget {
  final bool locked;
  final VoidCallback onTap;
  const _ScanButton({required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = locked
        ? const LinearGradient(
            colors: [Color(0xFFf59e0b), Color(0xFFd97706)])
        : const LinearGradient(
            colors: [Color(0xFF10b981), Color(0xFF059669)]);

    final glow = locked
        ? const Color(0xFFf59e0b)
        : const Color(0xFF10b981);

    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 6),
          boxShadow: [
            BoxShadow(color: glow.withOpacity(0.9), blurRadius: 60),
            BoxShadow(color: glow.withOpacity(0.5), blurRadius: 30),
          ],
        ),
        child: const Center(
          child: Text('🔍', style: TextStyle(fontSize: 45)),
        ),
      ),
    );

    if (locked) {
      btn = btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 500.ms);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn,
        if (locked) ...[
          const SizedBox(height: 8),
          const Text(
            'TAP TO CAPTURE!',
            style: TextStyle(
                color: Color(0xFFf59e0b),
                fontSize: 12,
                fontWeight: FontWeight.bold),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -5, duration: 700.ms),
        ]
      ],
    );
  }
}

// ─── Forest fallback background (when no camera) ─────────────────────────────

class _ForestFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF87CEEB),
            Color(0xFF5fb878),
            Color(0xFF3a7d4a),
            Color(0xFF1a4d2e),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Sun
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            right: MediaQuery.of(context).size.width * 0.18,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x99FFD700),
                      blurRadius: 80,
                      spreadRadius: 20),
                ],
              ),
            ),
          ),
          // Trees
          ..._buildTrees(context),
        ],
      ),
    );
  }

  List<Widget> _buildTrees(BuildContext context) {
    final positions = [0.06, 0.24, 0.45, 0.66, 0.88];
    final scales    = [0.65, 0.95, 0.80, 1.05, 0.70];
    final h = MediaQuery.of(context).size.height;

    return List.generate(5, (i) {
      return Positioned(
        left: MediaQuery.of(context).size.width * positions[i],
        bottom: 0,
        child: Transform.scale(
          scale: scales[i],
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 100,
            height: h * 0.55,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Trunk
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 45,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3d2817), Color(0xFF5c3d2e)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(-6, 0)),
                      ],
                    ),
                  ),
                ),
                // Crown
                Positioned(
                  bottom: 120,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF2d5016), Color(0xFF1a3010)],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 35),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
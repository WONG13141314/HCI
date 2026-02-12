// lib/screens/ar_game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ArGameScreenState extends State<ArGameScreen> with WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  bool _cameraReady = false;

  final GlobalKey _viewfinderKey = GlobalKey();

  Species? _modalSpecies;
  bool _modalIsNew = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;

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
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraCtrl;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.dispose();
    super.dispose();
  }

  Rect? _getViewfinderRect() {
    final ctx = _viewfinderKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size;
  }

  Future<void> _vibrate(List<int> pattern) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(pattern: pattern);
    }
  }

  void _onScan() {
    final ctrl = context.read<GameController>();
    if (!ctrl.targetLocked || ctrl.currentWildlife == null) {
      ctrl.showStatus('🎯 Centre wildlife in viewfinder first!');
      _vibrate([100]);
      return;
    }

    final sp = ctrl.currentWildlife!.species;
    final isNew = ctrl.scanTarget();
    _vibrate([200, 100, 200]);

    setState(() {
      _modalSpecies = sp;
      _modalIsNew = isNew;
    });
  }

  void _closeModal() {
    setState(() => _modalSpecies = null);
  }

  void _showCollection() {
    final ctrl = context.read<GameController>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📚 Collection'),
        content: ctrl.discoveredIds.isEmpty
            ? Text('No species yet!\n\nMove camera to find wildlife.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ctrl.discoveredIds.map((id) {
                    final sp = allSpecies.firstWhere((s) => s.id == id);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('${sp.icon} ${sp.name}',
                          style: TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          )
        ],
      ),
    );
  }

  void _showHelp() {
    final ctrl = context.read<GameController>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ℹ️ How to Play'),
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
            child: Text('Got it!'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get safe screen dimensions
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safePadding = mediaQuery.padding;
    
    return Consumer<GameController>(
      builder: (context, ctrl, _) {
        final wildlifePos = ctrl.wildlifeScreenPosition(screenSize);

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
          body: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera feed
                if (_cameraReady && _cameraCtrl != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraCtrl!.value.previewSize?.height ?? screenSize.width,
                        height: _cameraCtrl!.value.previewSize?.width ?? screenSize.height,
                        child: CameraPreview(_cameraCtrl!),
                      ),
                    ),
                  )
                else
                  Positioned.fill(child: _ForestFallback()),

                // Wildlife sprite
                if (wildlifePos != null && ctrl.currentWildlife != null)
                  WildlifeSprite(
                    key: ValueKey(ctrl.currentWildlife!.species.id),
                    species: ctrl.currentWildlife!.species,
                    position: wildlifePos,
                    targeted: ctrl.targetLocked,
                  ),

                // AR Viewfinder
                Center(
                  child: ArViewfinder(
                    locked: ctrl.targetLocked,
                    viewfinderKey: _viewfinderKey,
                  ),
                ),

                // Instruction hint
                if (ctrl.currentWildlife == null)
                  Positioned(
                    top: screenSize.height * 0.25,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Color(0xFF10b981).withOpacity(0.6), width: 2),
                      ),
                      child: Text(
                        '📱 Pan your camera slowly...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Top HUD
                Positioned(
                  top: safePadding.top + 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatBox(icon: '🏆', value: '${ctrl.points}'),
                        SizedBox(width: 12),
                        _StatBox(
                            icon: '📍',
                            value: '${ctrl.discoveredIds.length}/6'),
                      ],
                    ),
                  ),
                ),

                // Status message
                Positioned(
                  top: safePadding.top + 90,
                  left: 16,
                  right: 16,
                  child: AnimatedOpacity(
                    opacity: ctrl.statusVisible ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Color(0xFF10b981).withOpacity(0.6), width: 2),
                      ),
                      child: Text(
                        ctrl.statusMessage,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: safePadding.bottom + 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlBtn(icon: 'ℹ️', onTap: _showHelp),
                        _ScanButton(locked: ctrl.targetLocked, onTap: _onScan),
                        _ControlBtn(icon: '📚', onTap: _showCollection),
                      ],
                    ),
                  ),
                ),

                // Species modal
                if (_modalSpecies != null)
                  SpeciesModal(
                    species: _modalSpecies!,
                    isNew: _modalIsNew,
                    onClose: _closeModal,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon, value;
  const _StatBox({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF10b981).withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
        ),
        child: Center(
          child: Text(icon, style: TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool locked;
  final VoidCallback onTap;
  const _ScanButton({required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = locked
        ? LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFd97706)])
        : LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]);

    final glow = locked ? Color(0xFFf59e0b) : Color(0xFF10b981);

    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
          boxShadow: [
            BoxShadow(color: glow.withOpacity(0.6), blurRadius: 32),
            BoxShadow(color: glow.withOpacity(0.3), blurRadius: 16),
          ],
        ),
        child: Center(
          child: Text('🔍', style: TextStyle(fontSize: 40)),
        ),
      ),
    );

    if (locked) {
      btn = btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.06, duration: 500.ms);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn,
        if (locked) ...[
          SizedBox(height: 6),
          Text(
            'TAP TO CAPTURE!',
            style: TextStyle(
                color: Color(0xFFf59e0b),
                fontSize: 11,
                fontWeight: FontWeight.bold),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -3, duration: 600.ms),
        ]
      ],
    );
  }
}

class _ForestFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
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
          Positioned(
            top: size.height * 0.12,
            right: size.width * 0.18,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x99FFD700),
                      blurRadius: 60,
                      spreadRadius: 15),
                ],
              ),
            ),
          ),
          ..._buildTrees(size),
        ],
      ),
    );
  }

  List<Widget> _buildTrees(Size size) {
    final positions = [0.06, 0.24, 0.45, 0.66, 0.88];
    final scales = [0.65, 0.95, 0.80, 1.05, 0.70];

    return List.generate(5, (i) {
      return Positioned(
        left: size.width * positions[i],
        bottom: 0,
        child: Transform.scale(
          scale: scales[i],
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 90,
            height: size.height * 0.5,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3d2817), Color(0xFF5c3d2e)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(-4, 0)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 110,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF2d5016), Color(0xFF1a3010)],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black38, blurRadius: 25),
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
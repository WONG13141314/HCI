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
  
  const ArGameScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  State<ArGameScreen> createState() => _ArGameScreenState();
}

class _ArGameScreenState extends State<ArGameScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  bool _cameraReady = false;
  bool _isDisposed = false;

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
    if (_isDisposed) return;
    if (widget.cameras.isEmpty) {
      setState(() => _cameraReady = false);
      return;
    }

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
      if (!_isDisposed && mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (!_isDisposed && mounted) {
        setState(() => _cameraReady = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraCtrl?.dispose();
      setState(() {
        _cameraReady = false;
        _cameraCtrl = null;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.dispose();
    super.dispose();
  }

  Rect? _getViewfinderRect() {
    final ctx = _viewfinderKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size;
  }

  Future<void> _vibrate(List<int> pattern) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
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
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('📚', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'My Collection',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (ctrl.discoveredIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        'No species discovered yet!\n\nMove your camera to find wildlife.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: ctrl.discoveredIds.length,
                    itemBuilder: (context, index) {
                      final sp = allSpecies.firstWhere(
                        (s) => s.id == ctrl.discoveredIds[index],
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10b981).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(sp.icon, style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sp.name,
                                    style: TextStyle(fontFamily: 'Roboto', 
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    sp.statusLabel,
                                    style: TextStyle(fontFamily: 'Roboto', 
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${sp.points}',
                                style: TextStyle(fontFamily: 'Roboto', 
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('ℹ️', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'How to Play',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _HelpStep(
                number: '1',
                text: 'Pan your camera slowly around you',
              ),
              const SizedBox(height: 12),
              _HelpStep(
                number: '2',
                text: 'Wildlife will appear nearby in AR',
              ),
              const SizedBox(height: 12),
              _HelpStep(
                number: '3',
                text: 'Pan until it enters the green viewfinder',
              ),
              const SizedBox(height: 12),
              _HelpStep(
                number: '4',
                text: 'Tap SCAN when locked (turns amber)',
              ),
              const SizedBox(height: 24),
              Consumer<GameController>(
                builder: (context, ctrl, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF10b981),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Progress: ${ctrl.discoveredIds.length}/6',
                          style: TextStyle(fontFamily: 'Roboto', 
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safePadding = mediaQuery.padding;

    return Consumer<GameController>(
      builder: (context, ctrl, _) {
        final wildlifePos = ctrl.wildlifeScreenPosition(screenSize);

        if (wildlifePos != null && ctrl.currentWildlife != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
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
                // Camera feed or forest fallback
                if (_cameraReady && _cameraCtrl != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraCtrl!.value.previewSize?.height ?? 
                               screenSize.width,
                        height: _cameraCtrl!.value.previewSize?.width ?? 
                                screenSize.height,
                        child: CameraPreview(_cameraCtrl!),
                      ),
                    ),
                  )
                else
                  const Positioned.fill(child: _ForestFallback()),

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

                // Hint overlay when no wildlife
                if (ctrl.currentWildlife == null)
                  Positioned(
                    top: screenSize.height * 0.28,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10b981).withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('📱', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Move your camera slowly...',
                              style: TextStyle(fontFamily: 'Roboto', 
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0, duration: 600.ms),

                // Top HUD
                Positioned(
                  top: safePadding.top + 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _StatBox(
                        icon: '🏆',
                        value: '${ctrl.points}',
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        icon: '📍',
                        value: '${ctrl.discoveredIds.length}/6',
                      ),
                    ],
                  ),
                ),

                // Status message
                Positioned(
                  top: safePadding.top + 90,
                  left: 16,
                  right: 16,
                  child: AnimatedOpacity(
                    opacity: ctrl.statusVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10b981).withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10b981).withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Text(
                        ctrl.statusMessage,
                        style: TextStyle(fontFamily: 'Roboto', 
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: safePadding.bottom + 24,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlBtn(
                          icon: Icons.help_outline_rounded,
                          onTap: _showHelp,
                        ),
                        _ScanButton(
                          locked: ctrl.targetLocked,
                          onTap: _onScan,
                        ),
                        _ControlBtn(
                          icon: Icons.collections_bookmark_rounded,
                          onTap: _showCollection,
                        ),
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

// Helper widgets
class _StatBox extends StatelessWidget {
  final String icon;
  final String value;

  const _StatBox({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10b981).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(fontFamily: 'Roboto', 
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
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
          color: Colors.black.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
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
        ? const LinearGradient(
            colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
          )
        : const LinearGradient(
            colors: [Color(0xFF10b981), Color(0xFF059669)],
          );

    final glowColor = locked ? const Color(0xFFf59e0b) : const Color(0xFF10b981);

    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.6),
              blurRadius: 35,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 20,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.center_focus_strong,
            color: Colors.white,
            size: 44,
          ),
        ),
      ),
    );

    if (locked) {
      btn = btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.08,
            duration: 500.ms,
            curve: Curves.easeInOut,
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn,
        if (locked) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFf59e0b),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFf59e0b).withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              'TAP TO SCAN!',
              style: TextStyle(fontFamily: 'Roboto', 
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -4, duration: 600.ms),
        ],
      ],
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String number;
  final String text;

  const _HelpStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF10b981).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10b981),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(fontFamily: 'Roboto', 
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10b981),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontFamily: 'Roboto', 
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _ForestFallback extends StatelessWidget {
  const _ForestFallback();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF87CEEB), // Sky blue
            Color(0xFF5fb878), // Light green
            Color(0xFF3a7d4a), // Medium green
            Color(0xFF1a4d2e), // Dark green
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Sun
          Positioned(
            top: size.height * 0.12,
            right: size.width * 0.18,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x99FFD700),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),
          ),
          
          // Trees
          ..._buildTrees(size),
          
          // Overlay text
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10b981).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌲', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Forest View Mode',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camera not available.\nUsing simulated forest environment.',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
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
                // Trunk
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3d2817), Color(0xFF5c3d2e)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                // Foliage
                Positioned(
                  bottom: 110,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF2d5016), Color(0xFF1a3010)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 25,
                        ),
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
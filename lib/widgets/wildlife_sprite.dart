// lib/widgets/wildlife_sprite.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/species.dart';

class WildlifeSprite extends StatefulWidget {
  final Species species;
  final Offset position; // pixel position on screen
  final bool targeted;

  const WildlifeSprite({
    super.key,
    required this.species,
    required this.position,
    required this.targeted,
  });

  @override
  State<WildlifeSprite> createState() => _WildlifeSpriteState();
}

class _WildlifeSpriteState extends State<WildlifeSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Position is the centre of the sprite on screen
    return Positioned(
      left: widget.position.dx - 60, // half of sprite width ~120
      top:  widget.position.dy - 75, // vertically centred
      child: _buildSprite(),
    );
  }

  Widget _buildSprite() {
    Widget sprite = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.targeted
                  ? const Color(0xFFf59e0b)
                  : const Color(0xFF10b981).withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 15)
            ],
          ),
          child: Text(
            widget.species.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 8),
        // Emoji icon
        Text(
          widget.species.icon,
          style: TextStyle(
            fontSize: 85,
            shadows: [
              Shadow(
                color: widget.targeted
                    ? const Color(0xFF10b981)
                    : Colors.black.withOpacity(0.7),
                blurRadius: widget.targeted ? 30 : 15,
              ),
            ],
          ),
        ),
      ],
    );

    // Floating animation when idle
    if (!widget.targeted) {
      sprite = AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -15 * _floatCtrl.value),
          child: child,
        ),
        child: sprite,
      );
    } else {
      // Pulse when targeted
      sprite = sprite
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.15, duration: 600.ms);
    }

    // Pop-in when first shown
    return sprite
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .rotate(begin: -0.5, end: 0, duration: 600.ms);
  }
}

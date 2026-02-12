import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/species.dart';

class WildlifeSprite extends StatefulWidget {
  final Species species;
  final Offset position;
  final bool targeted;

  const WildlifeSprite({
    Key? key,
    required this.species,
    required this.position,
    required this.targeted,
  }) : super(key: key);

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
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 70,
      top: widget.position.dy - 90,
      child: _buildSprite(),
    );
  }

  Widget _buildSprite() {
    final borderColor = widget.targeted
        ? const Color(0xFFf59e0b)
        : const Color(0xFF10b981);

    Widget sprite = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name label with modern styling
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 15,
              ),
            ],
          ),
          child: Text(
            widget.species.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Icon with glow effect
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.targeted
                    ? const Color(0xFFf59e0b).withOpacity(0.6)
                    : const Color(0xFF10b981).withOpacity(0.4),
                blurRadius: widget.targeted ? 35 : 25,
                spreadRadius: widget.targeted ? 8 : 4,
              ),
            ],
          ),
          child: Text(
            widget.species.icon,
            style: TextStyle(
              fontSize: 70,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // Floating animation when not targeted
    if (!widget.targeted) {
      sprite = AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            -12 * _floatCtrl.value,
          ),
          child: child,
        ),
        child: sprite,
      );
    } else {
      // Pulse effect when targeted
      sprite = sprite
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.12,
            duration: 550.ms,
            curve: Curves.easeInOut,
          );
    }

    // Entrance animation
    return sprite
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 700.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms)
        .rotate(
          begin: -0.3,
          end: 0,
          duration: 700.ms,
        );
  }
}
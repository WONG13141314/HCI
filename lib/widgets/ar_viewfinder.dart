import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArViewfinder extends StatefulWidget {
  final bool locked;
  final GlobalKey viewfinderKey;

  const ArViewfinder({
    Key? key,
    required this.locked,
    required this.viewfinderKey,
  }) : super(key: key);

  @override
  State<ArViewfinder> createState() => _ArViewfinderState();
}

class _ArViewfinderState extends State<ArViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _scanAnim = CurvedAnimation(
      parent: _scanCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.locked 
        ? const Color(0xFFf59e0b) 
        : const Color(0xFF10b981);
    const size = 260.0;

    return SizedBox(
      key: widget.viewfinderKey,
      width: size,
      height: size,
      child: Stack(
        children: [
          // Outer glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Main frame
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
          ),

          // Animated corners
          _AnimatedCorner(top: true, left: true, color: color, locked: widget.locked),
          _AnimatedCorner(top: true, left: false, color: color, locked: widget.locked),
          _AnimatedCorner(top: false, left: true, color: color, locked: widget.locked),
          _AnimatedCorner(top: false, left: false, color: color, locked: widget.locked),

          // Center crosshair
          Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: _CrosshairPainter(color: color),
              ),
            ),
          ),

          // Scan line (only when searching)
          if (!widget.locked)
            AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) {
                return Positioned(
                  top: _scanAnim.value * (size - 6),
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          color.withOpacity(0.8),
                          color,
                          color.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Locked indicator - pulsing ring
          if (widget.locked)
            Center(
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.8),
                    width: 3,
                  ),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 0.85,
                  end: 1.0,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(begin: 0.5, end: 1.0, duration: 600.ms),

          // Lock icon when targeted
          if (widget.locked)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                  curve: Curves.elasticOut,
                ),
        ],
      ),
    );
  }
}

class _AnimatedCorner extends StatelessWidget {
  final bool top;
  final bool left;
  final Color color;
  final bool locked;

  const _AnimatedCorner({
    required this.top,
    required this.left,
    required this.color,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    Widget corner = Positioned(
      top: top ? -4 : null,
      bottom: top ? null : -4,
      left: left ? -4 : null,
      right: left ? null : -4,
      child: SizedBox(
        width: 50,
        height: 50,
        child: CustomPaint(
          painter: _CornerPainter(
            color: color,
            top: top,
            left: left,
          ),
        ),
      ),
    );

    if (locked) {
      corner = corner
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 800.ms,
            color: color.withOpacity(0.3),
          );
    }

    return corner;
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = left ? 4.0 : size.width - 4;
    final y = top ? 4.0 : size.height - 4;
    final dx = left ? 32.0 : -32.0;
    final dy = top ? 32.0 : -32.0;

    // Horizontal line
    canvas.drawLine(
      Offset(x, y),
      Offset(x + dx, y),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    const gap = 8.0;
    const length = 12.0;

    // Vertical line (top)
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, center.dy - gap),
      paint,
    );

    // Vertical line (bottom)
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, size.height),
      paint,
    );

    // Horizontal line (left)
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );

    // Horizontal line (right)
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(size.width, center.dy),
      paint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      3,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.color != color;
}
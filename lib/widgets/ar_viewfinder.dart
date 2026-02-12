// lib/widgets/ar_viewfinder.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArViewfinder extends StatefulWidget {
  final bool locked;
  final GlobalKey viewfinderKey;

  const ArViewfinder({
    super.key,
    required this.locked,
    required this.viewfinderKey,
  });

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
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.locked ? const Color(0xFFf59e0b) : const Color(0xFF10b981);
    const size = 240.0;

    return SizedBox(
      key: widget.viewfinderKey,
      width: size,
      height: size,
      child: Stack(
        children: [
          // Outer frame
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.4), width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          // Corners
          _Corner(top: true,  left: true,  color: color),
          _Corner(top: true,  left: false, color: color),
          _Corner(top: false, left: true,  color: color),
          _Corner(top: false, left: false, color: color),

          // Crosshair
          Center(
            child: SizedBox(
              width: 35,
              height: 35,
              child: CustomPaint(painter: _CrosshairPainter(color: color)),
            ),
          ),

          // Scan line (only when not locked)
          if (!widget.locked)
            AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) => Positioned(
                top: _scanAnim.value * size,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, color, Colors.transparent],
                    ),
                    boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                  ),
                ),
              ),
            ),

          // Locked pulse ring
          if (widget.locked)
            Center(
              child: SizedBox(
                width: size * 0.6,
                height: size * 0.6,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf59e0b)),
                  strokeWidth: 3,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scaleXY(begin: 0.9, end: 1.1, duration: 500.ms),
        ],
      ),
    );
  }
}

// ─── Corner widget ─────────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final bool top, left;
  final Color color;
  const _Corner({required this.top, required this.left, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:    top    ? -4 : null,
      bottom: top    ? null : -4,
      left:   left   ? -4 : null,
      right:  left   ? null : -4,
      child: SizedBox(
        width: 45,
        height: 45,
        child: CustomPaint(
          painter: _CornerPainter(
              color: color, top: top, left: left),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top, left;
  _CornerPainter({required this.color, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top  ? 0.0 : size.height;
    final dx = left ?  28.0 : -28.0;
    final dy = top  ?  28.0 : -28.0;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ─── Crosshair painter ─────────────────────────────────────────────────────

class _CrosshairPainter extends CustomPainter {
  final Color color;
  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.color != color;
}

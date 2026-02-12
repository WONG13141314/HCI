import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10b981),
            Color(0xFF059669),
            Color(0xFF047857),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            
            // Animated icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Text(
                '🌿',
                style: TextStyle(fontSize: 120),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .rotate(
                  begin: 0,
                  end: 0.02,
                  duration: 2000.ms,
                ),

            const SizedBox(height: 40),

            // App title
            Text(
              'WildTrack AR',
              style: TextStyle(fontFamily: 'Roboto', 
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 200.ms),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Genting Nature Adventures',
              style: TextStyle(fontFamily: 'Roboto', 
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 400.ms),

            const SizedBox(height: 16),

            // Mission statement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Discover • Learn • Protect',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Roboto', 
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 2,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 600.ms),

            const Spacer(flex: 2),

            // Loading indicator
            Column(
              children: [
                Text(
                  'Initializing AR Experience...',
                  style: TextStyle(fontFamily: 'Roboto', 
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 2400),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 6,
                        );
                      },
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 1000.ms),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
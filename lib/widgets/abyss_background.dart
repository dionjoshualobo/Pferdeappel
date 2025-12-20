import 'package:flutter/material.dart';
import 'dart:math' as math;

/// The dark abyss background layer with animated stars
/// 
/// ASSET NOTE: Replace this with an actual image asset for production:
/// AssetImage('assets/images/abyss_bg.png')
class AbyssBackground extends StatefulWidget {
  const AbyssBackground({super.key});

  @override
  State<AbyssBackground> createState() => _AbyssBackgroundState();
}

class _AbyssBackgroundState extends State<AbyssBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Generate random stars
    final random = math.Random(42);
    _stars = List.generate(80, (_) => _Star.random(random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF1a1a2e), // Dark navy center
            Color(0xFF0f0f1a), // Near black edges
            Color(0xFF000000), // Pure black
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _StarfieldPainter(
              stars: _stars,
              animationValue: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double twinkleOffset;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });

  factory _Star.random(math.Random random) {
    return _Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 2 + 0.5,
      twinkleSpeed: random.nextDouble() * 3 + 1,
      twinkleOffset: random.nextDouble() * math.pi * 2,
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;

  _StarfieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final opacity = (math.sin(
                animationValue * math.pi * 2 * star.twinkleSpeed + star.twinkleOffset,
              ) +
              1) /
          2;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 + opacity * 0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 0.5);

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }

    // Add subtle nebula clouds
    _drawNebula(canvas, size);
  }

  void _drawNebula(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          const Color(0xFF4a1a6b).withValues(alpha: 0.15), // Purple nebula
          const Color(0xFF1a4a6b).withValues(alpha: 0.1), // Blue tint
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

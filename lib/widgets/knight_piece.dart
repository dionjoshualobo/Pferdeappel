import 'package:flutter/material.dart';
import '../models/models.dart';

/// Knight piece widget that represents a player on the board
/// Uses the Unicode chess knight symbol for an authentic look
class KnightPiece extends StatelessWidget {
  final Player player;
  final double size;
  final GameSettings settings;

  const KnightPiece({
    super.key,
    required this.player,
    required this.settings,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = player.getColor(settings);
    final accentColor = player.getAccentColor(settings);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            color,
            accentColor,
            accentColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          // Outer glow
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          // Drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        // Unicode chess knight: ♞ (black) or ♘ (white outline)
        child: Text(
          '♞', // Black Chess Knight Unicode symbol
          style: TextStyle(
            fontSize: size * 0.65,
            color: Colors.white.withValues(alpha: 0.95),
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large knight piece for home screen (uses same symbol)
class LargeKnightPiece extends StatelessWidget {
  final Color color;
  final double size;

  const LargeKnightPiece({
    super.key,
    required this.color,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = GameSettings.getAccentColor(color);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            color,
            accentColor,
            accentColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '♞',
          style: TextStyle(
            fontSize: size * 0.6,
            color: Colors.white.withValues(alpha: 0.95),
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated wrapper for knight piece movement
class AnimatedKnightPiece extends StatelessWidget {
  final Player player;
  final double size;
  final Duration duration;
  final GameSettings settings;

  const AnimatedKnightPiece({
    super.key,
    required this.player,
    required this.settings,
    this.size = 40,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: KnightPiece(player: player, size: size, settings: settings),
    );
  }
}

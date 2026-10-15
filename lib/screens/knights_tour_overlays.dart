import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';

/// Overlay shown when Knight's Tour is completed successfully
class KnightsTourCompleteOverlay extends ConsumerWidget {
  final GameSettings settings;
  final VoidCallback? onHomePressed;

  const KnightsTourCompleteOverlay({
    super.key,
    required this.settings,
    this.onHomePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = settings.player1Color;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 45,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Success text
                Text(
                  'Tour Complete!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'You visited every square!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 24),

                // Play Again button
                _OverlayButton(
                  label: 'Play Again',
                  icon: Icons.replay,
                  color: color,
                  filled: true,
                  onTap: () => ref.read(gameStateProvider.notifier).resetGame(),
                ),

                const SizedBox(height: 16),

                // Home button
                _OverlayButton(
                  label: 'Home',
                  icon: Icons.home,
                  color: color,
                  filled: false,
                  onTap: onHomePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay shown when Knight's Tour fails (no valid moves, tour incomplete)
class KnightsTourFailedOverlay extends ConsumerWidget {
  final GameSettings settings;
  final VoidCallback? onHomePressed;

  const KnightsTourFailedOverlay({
    super.key,
    required this.settings,
    this.onHomePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final tilesRemaining = gameState.countActiveTiles();

    const color = Color(0xFFE74C3C); // Red for failure

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Failed icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        color,
                        Color(0xB3E74C3C),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Failed text
                Text(
                  'Tour Incomplete',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'No valid moves left!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$tilesRemaining squares remaining',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(height: 24),

                // Try Again button
                _OverlayButton(
                  label: 'Try Again',
                  icon: Icons.replay,
                  color: color,
                  filled: true,
                  onTap: () => ref.read(gameStateProvider.notifier).resetGame(),
                ),

                const SizedBox(height: 16),

                // Home button
                _OverlayButton(
                  label: 'Home',
                  icon: Icons.home,
                  color: color,
                  filled: false,
                  onTap: onHomePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared pill button used by the Knight's Tour overlays
class _OverlayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                )
              : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

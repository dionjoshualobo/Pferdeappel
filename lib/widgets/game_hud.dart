import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';

/// HUD displaying current player turn and game status
class GameHud extends ConsumerWidget {
  final VoidCallback? onHomePressed;
  
  const GameHud({super.key, this.onHomePressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final isGameOver = ref.watch(isGameOverProvider);
    final winner = ref.watch(winnerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row with home button and title
          Row(
            children: [
              // Home button
              IconButton(
                onPressed: onHomePressed,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
              
              // Game title
              Expanded(
                child: Text(
                  'PFERDEÄPPEL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: const Color(0xFF6B4EFF).withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Restart button
              IconButton(
                onPressed: () => ref.read(gameStateProvider.notifier).resetGame(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.replay,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Turn indicator or winner display
          if (isGameOver && winner != null)
            _buildWinnerDisplay(winner, gameState.settings, ref)
          else
            _buildTurnIndicator(gameState.currentPlayer, gameState.settings),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(Player currentPlayer, GameSettings settings) {
    final color = currentPlayer.getColor(settings);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${currentPlayer.displayName}'s Turn",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerDisplay(Player winner, GameSettings settings, WidgetRef ref) {
    final color = winner.getColor(settings);
    final accentColor = winner.getAccentColor(settings);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                accentColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events,
                size: 48,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${winner.displayName} Wins!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ref.read(gameStateProvider.notifier).resetGame(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2a2a3c),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.5),
          ),
          icon: const Icon(Icons.replay),
          label: const Text(
            'Play Again',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

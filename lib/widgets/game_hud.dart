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
          
          // Always show turn indicator (win overlay handled in game_screen)
          _buildTurnIndicator(gameState.currentPlayer, gameState.settings),
          
          // Show tiles remaining for Knight's Tour
          if (gameState.settings.gameMode == GameMode.knightsTour)
            _buildTilesRemaining(gameState),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(Player currentPlayer, GameSettings settings) {
    final color = currentPlayer.getColor(settings);
    
    // For Knight's Tour, show different text
    final isKnightsTour = settings.gameMode == GameMode.knightsTour;
    final text = isKnightsTour ? "Knight's Tour" : "${currentPlayer.getDisplayName(settings)}'s Turn";
    
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
            text,
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

  Widget _buildTilesRemaining(GameState gameState) {
    final tilesRemaining = gameState.countActiveTiles();
    final totalTiles = gameState.gridSize * gameState.gridSize;
    
    // In Knight's Tour, the tile the knight is currently on counts as visited
    // Calculate: tiles that have fallen away + 1 (current tile) = tiles visited
    // But if knight hasn't been placed yet (moveCount == 0), show 0 visited
    final tilesVisited = gameState.moveCount == 0 
        ? 0 
        : totalTiles - tilesRemaining + 1;
    
    final color = gameState.settings.player1Color;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          'Visited: $tilesVisited / $totalTiles',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

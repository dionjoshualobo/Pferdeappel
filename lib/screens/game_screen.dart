import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../widgets/widgets.dart';

/// Main game screen with layered Stack architecture
class GameScreen extends ConsumerWidget {
  final VoidCallback? onHomePressed;
  
  const GameScreen({super.key, this.onHomePressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final isPlayer2FirstMove = gameState.isPlayer2FirstMove;
    final isSmallBoard = gameState.gridSize == 4;
    final isGameOver = ref.watch(isGameOverProvider);
    final winner = ref.watch(winnerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // LAYER 1 (Bottom): The Abyss Background
            const AbyssBackground(),

            // LAYER 2 (Middle): Board frame glow effect
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // LAYER 3 (Top): Game content
            Column(
              children: [
                // Top HUD with home and restart buttons
                GameHud(onHomePressed: onHomePressed),

                // Game Board (takes remaining space)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: GameBoard(),
                  ),
                ),

                // Bottom spacing
                const SizedBox(height: 24),
              ],
            ),

            // Vignette overlay for dramatic effect
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            
            // First move protection message overlay (only on small boards)
            if (isPlayer2FirstMove && isSmallBoard)
              const _FirstMoveOverlay(),
            
            // Win overlay
            if (isGameOver && winner != null)
              _WinOverlay(winner: winner, settings: gameState.settings),
            
            // Tie overlay
            if (isGameOver && winner == null && ref.watch(isTieProvider))
              const _TieOverlay(),
          ],
        ),
      ),
    );
  }
}

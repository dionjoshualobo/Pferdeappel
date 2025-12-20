import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import 'game_tile.dart';
import 'knight_piece.dart';

/// The main game board widget with grid and pieces
class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final validMoves = ref.watch(validMovesProvider);
    final gridSize = gameState.gridSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate tile size based on available space
        final boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final tileSize = (boardSize - 32) / gridSize; // Account for padding

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // The NxN grid of tiles
                _buildGrid(context, ref, gameState, validMoves, tileSize, gridSize),
                
                // Player pieces overlay - IgnorePointer so taps pass through
                // to tiles underneath (important for capture moves!)
                IgnorePointer(
                  child: _buildPieces(context, gameState, tileSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    List<Position> validMoves,
    double tileSize,
    int gridSize,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(gridSize, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(gridSize, (col) {
            final position = Position(row, col);
            final tileState = gameState.getTileAt(position);
            final isValidMove = validMoves.contains(position);

            return SizedBox(
              width: tileSize,
              height: tileSize,
              child: GameTile(
                tileState: tileState,
                position: position,
                isValidMove: isValidMove && 
                    gameState.result == GameResult.ongoing &&
                    gameState.fallingTilePosition == null, // Hide during fall animation
                hasPlayer1: gameState.player1Position == position,
                hasPlayer2: gameState.player2Position == position,
                onTap: () => _handleTileTap(ref, position),
                onFallComplete: () => _handleFallComplete(ref),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildPieces(
    BuildContext context,
    GameState gameState,
    double tileSize,
  ) {
    return Stack(
      children: [
        // Player 1 piece
        _buildAnimatedPiece(
          gameState.player1Position,
          Player.player1,
          tileSize,
          gameState.settings,
          key: const ValueKey('player1'),
        ),
        // Player 2 piece
        _buildAnimatedPiece(
          gameState.player2Position,
          Player.player2,
          tileSize,
          gameState.settings,
          key: const ValueKey('player2'),
        ),
      ],
    );
  }

  Widget _buildAnimatedPiece(
    Position position,
    Player player,
    double tileSize,
    GameSettings settings, {
    required Key key,
  }) {
    final pieceSize = tileSize * 0.7;
    final offset = (tileSize - pieceSize) / 2;

    return AnimatedPositioned(
      key: key,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      left: position.col * tileSize + offset,
      top: position.row * tileSize + offset,
      child: AnimatedKnightPiece(
        player: player,
        size: pieceSize,
        settings: settings,
      ),
    );
  }

  void _handleTileTap(WidgetRef ref, Position position) {
    ref.read(gameStateProvider.notifier).makeMove(position);
  }

  void _handleFallComplete(WidgetRef ref) {
    ref.read(gameStateProvider.notifier).onTileFallComplete();
  }
}

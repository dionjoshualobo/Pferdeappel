import '../../models/models.dart';

/// Base interface for AI strategies
abstract class AIStrategy {
  /// Get the best move for the current player
  Position? getBestMove(GameState state);
  
  /// Strategy name for debugging
  String get name;
}

/// Common utility methods shared by all strategies
mixin AIUtilities {
  /// Check if capture is allowed (respects 4x4 first move rule)
  bool canCapture(GameState state) => !state.isPlayer2FirstMove;
  
  /// Count valid moves from a position
  int countMobility(GameState state, Position pos) {
    return pos.getKnightMoves(state.gridSize).where((p) {
      if (!p.isOnBoard(state.gridSize)) return false;
      return state.board[p.row][p.col].isPlayable;
    }).length;
  }
  
  /// Simulate a move and return resulting state
  GameState simulateMove(GameState state, Position target) {
    final currentPos = state.getPlayerPosition(state.currentPlayer);
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);

    final newBoard = state.copyBoard();
    newBoard[currentPos.row][currentPos.col] = const TileState(status: TileStatus.void_);

    final Position newP1Pos;
    final Position newP2Pos;

    if (state.currentPlayer == Player.player1) {
      newP1Pos = target;
      newP2Pos = state.player2Position;
    } else {
      newP1Pos = state.player1Position;
      newP2Pos = target;
    }

    GameResult result = GameResult.ongoing;
    if (target == opponentPos && canCapture(state)) {
      result = state.currentPlayer == Player.player1
          ? GameResult.player1Wins
          : GameResult.player2Wins;
    }

    final newState = state.copyWith(
      board: newBoard,
      player1Position: newP1Pos,
      player2Position: newP2Pos,
      currentPlayer: state.currentPlayer.opponent,
      result: result,
      moveCount: state.moveCount + 1,
    );

    // Check if opponent is trapped
    if (result == GameResult.ongoing && newState.getValidMoves().isEmpty) {
      return newState.copyWith(
        result: state.currentPlayer == Player.player1
            ? GameResult.player1Wins
            : GameResult.player2Wins,
      );
    }

    return newState;
  }
  
  /// Find immediate winning move (capture or trap)
  Position? findImmediateWin(GameState state, List<Position> moves) {
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    for (final move in moves) {
      // Capture win
      if (move == opponentPos && canCapture(state)) {
        return move;
      }
      
      // Trap win
      final simState = simulateMove(state, move);
      if (simState.result != GameResult.ongoing) {
        return move;
      }
    }
    return null;
  }
  
  /// Get edge penalty score
  double getEdgePenalty(Position pos, int gridSize) {
    double penalty = 0;
    if (pos.row == 0 || pos.row == gridSize - 1) penalty += 2;
    if (pos.col == 0 || pos.col == gridSize - 1) penalty += 2;
    if ((pos.row == 0 || pos.row == gridSize - 1) && 
        (pos.col == 0 || pos.col == gridSize - 1)) {
      penalty += 3; // Corner
    }
    return penalty;
  }
}

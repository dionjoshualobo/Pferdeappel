import '../../models/models.dart';

/// Pre-computed opening book for 4x4 boards
/// Contains optimal moves for common positions to ensure AI wins
class OpeningBook4x4 {
  /// Starting positions: P1 at (0,0), P2 at (3,3)
  /// Returns the optimal move for the given position, or null if not in book
  Position? getBookMove(GameState state) {
    if (state.gridSize != 4) return null;
    
    final p1 = state.player1Position;
    final p2 = state.player2Position;
    final isP1Turn = state.currentPlayer == Player.player1;
    final moveCount = state.moveCount;
    
    // Create position key: "p1row,p1col:p2row,p2col:currentPlayer:moveCount"
    final key = '${p1.row},${p1.col}:${p2.row},${p2.col}:${isP1Turn ? 1 : 2}:$moveCount';
    
    // Check if we have a book move for this position
    final bookMove = _openingBook[key];
    if (bookMove != null) {
      return Position(bookMove[0], bookMove[1]);
    }
    
    // Fallback: Use strategic patterns based on position analysis
    return _getStrategicMove(state);
  }
  
  /// Pre-computed opening book
  /// Key format: "p1Row,p1Col:p2Row,p2Col:currentPlayer(1or2):moveCount"
  /// Value: [targetRow, targetCol]
  static final Map<String, List<int>> _openingBook = {
    // ============ PLAYER 1 OPENINGS (AI is P1, starts at 0,0) ============
    // Move 1: P1's first move - go to center-ish position
    '0,0:3,3:1:0': [2, 1],  // Knight move from (0,0) to (2,1)
    '0,0:3,3:1:1': [1, 2],  // Alternative: (0,0) to (1,2)
    
    // Move 3: After P2 responds, common positions
    '2,1:1,2:1:2': [0, 2],  // Continue controlling the board
    '2,1:1,1:1:2': [3, 3],  // Capture if available (P2 hasn't moved from 3,3?)
    '2,1:2,2:1:2': [0, 0],  // Retreat and control
    '1,2:2,1:1:2': [3,3],   // Attack position
    '1,2:1,1:1:2': [0,0],   // Retreat
    
    // ============ PLAYER 2 OPENINGS (AI is P2, starts at 3,3) ============
    // Move 2: P2's first move after P1 moves
    // Note: P2 cannot capture P1 on first move (4x4 special rule)
    
    // If P1 went to (2,1)
    '2,1:3,3:2:1': [1,2],   // Go to (1,2) - controls center
    // If P1 went to (1,2)  
    '1,2:3,3:2:1': [2,1],   // Go to (2,1) - mirror control
    // If P1 went to other positions
    '2,1:3,3:2:2': [1,1],   // Alternative center control
    
    // ============ MID-GAME POSITIONS ============
    // These are positions after the opening where we have known good moves
    
    // Trap setups - when opponent has limited mobility
    '1,2:3,2:1:4': [2,0],   // Force opponent to corner
    '2,1:2,3:1:4': [0,2],   // Cut off escape routes
    
    // ============ WINNING POSITIONS ============
    // Positions where we can capture or trap
    '2,1:0,0:1:2': [1,3],   // P2 at corner, limit their moves
    '1,2:3,3:1:4': [3,3],   // Capture if possible
  };
  
  /// Strategic move generator for positions not in the book
  Position? _getStrategicMove(GameState state) {
    final moves = state.getValidMoves();
    if (moves.isEmpty) return null;
    
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    // Priority 1: Immediate capture (if allowed)
    if (!state.isPlayer2FirstMove) {
      for (final move in moves) {
        if (move == opponentPos) {
          return move;
        }
      }
    }
    
    // Priority 2: Trap opponent (leave them with 0 moves)
    for (final move in moves) {
      final simState = _simulateMove(state, move);
      if (simState.getValidMoves().isEmpty) {
        return move; // This traps opponent
      }
    }
    
    // Priority 3: Near-trap (leave opponent with 1 move)
    for (final move in moves) {
      final simState = _simulateMove(state, move);
      if (simState.getValidMoves().length == 1) {
        return move;
      }
    }
    
    // Priority 4: Minimize opponent's moves while maximizing ours
    Position? bestMove;
    double bestScore = double.negativeInfinity;
    
    for (final move in moves) {
      final simState = _simulateMove(state, move);
      final oppMoves = simState.getValidMoves();
      
      // Skip moves where opponent can capture us
      if (oppMoves.contains(move)) continue;
      
      // Score: opponent's mobility (lower = better for us)
      double score = -oppMoves.length * 100;
      
      // Bonus for moves near center
      score -= (move.row - 1.5).abs() * 10;
      score -= (move.col - 1.5).abs() * 10;
      
      // Bonus for our mobility after move
      final ourMobility = _countMobility(simState.copyWith(currentPlayer: state.currentPlayer), move);
      score += ourMobility * 50;
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    
    return bestMove ?? moves.first;
  }
  
  int _countMobility(GameState state, Position pos) {
    return pos.getKnightMoves(state.gridSize).where((p) {
      if (!p.isOnBoard(state.gridSize)) return false;
      return state.board[p.row][p.col].isPlayable;
    }).length;
  }
  
  GameState _simulateMove(GameState state, Position target) {
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
    if (target == opponentPos && !state.isPlayer2FirstMove) {
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

    if (result == GameResult.ongoing && newState.getValidMoves().isEmpty) {
      return newState.copyWith(
        result: state.currentPlayer == Player.player1
            ? GameResult.player1Wins
            : GameResult.player2Wins,
      );
    }

    return newState;
  }
}

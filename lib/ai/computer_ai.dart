import 'dart:math';
import '../models/models.dart';

/// AI engine for computing computer opponent moves
class ComputerAI {
  final Random _random = Random();

  /// Get the best move for the current player based on difficulty
  Position? getBestMove(GameState state, Difficulty difficulty) {
    final validMoves = state.getValidMoves();
    if (validMoves.isEmpty) return null;

    switch (difficulty) {
      case Difficulty.easy:
        return _getEasyMove(validMoves);
      case Difficulty.medium:
        return _getMediumMove(state, validMoves);
      case Difficulty.hard:
        return _getHardMove(state, validMoves);
      case Difficulty.impossible:
        return _getImpossibleMove(state, validMoves);
    }
  }

  /// Easy: Pick a random valid move
  Position _getEasyMove(List<Position> validMoves) {
    return validMoves[_random.nextInt(validMoves.length)];
  }

  /// Medium: Avoid captures, prefer high mobility, add randomness
  Position _getMediumMove(GameState state, List<Position> validMoves) {
    final scores = <Position, double>{};
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);

    for (final move in validMoves) {
      double score = 0;

      // Simulate the move to check opponent's response
      final simState = _simulateMove(state, move);
      final opponentMoves = simState.getValidMoves();

      // Avoid moves where opponent can capture us next turn
      final canBeCaptured = opponentMoves.contains(move);
      if (canBeCaptured) {
        score -= 50;
      }

      // Prefer moves with higher mobility (more escape routes)
      final futureState = _simulateMove(state, move);
      // Switch back to current player to count their moves from new position
      final mobilityState = futureState.copyWith(
        currentPlayer: state.currentPlayer,
      );
      final futureMoves = _countValidMovesFromPosition(mobilityState, move);
      score += futureMoves * 5;

      // Bonus for capturing opponent (if allowed)
      if (move == opponentPos && !state.isPlayer2FirstMove) {
        score += 100;
      }

      // Add small randomness to avoid predictability
      score += _random.nextDouble() * 3;

      scores[move] = score;
    }

    // Pick the move with highest score
    return _pickBestMove(scores);
  }

  /// Hard: 2-ply lookahead, pick from top moves with randomness
  Position _getHardMove(GameState state, List<Position> validMoves) {
    final scores = <Position, double>{};
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);

    for (final move in validMoves) {
      // Immediate win check
      if (move == opponentPos && !state.isPlayer2FirstMove) {
        scores[move] = 1000 + _random.nextDouble();
        continue;
      }

      // Simulate our move
      final afterOurMove = _simulateMove(state, move);
      
      // Check if opponent is trapped after our move
      if (afterOurMove.getValidMoves().isEmpty) {
        scores[move] = 900 + _random.nextDouble();
        continue;
      }

      // Evaluate opponent's best response
      double worstCaseScore = double.infinity;
      for (final oppMove in afterOurMove.getValidMoves()) {
        final afterOppMove = _simulateMove(afterOurMove, oppMove);
        
        // Our mobility after opponent moves
        final ourMobility = afterOppMove.getValidMoves().length.toDouble();
        
        // Check if we get trapped
        if (ourMobility == 0) {
          worstCaseScore = -1000;
          break;
        }
        
        // Check if opponent can capture us
        if (oppMove == move) {
          worstCaseScore = min(worstCaseScore, -500);
          continue;
        }

        final score = ourMobility * 10;
        worstCaseScore = min(worstCaseScore, score);
      }

      scores[move] = worstCaseScore + _random.nextDouble() * 2;
    }

    // Pick from top 3 moves randomly for unpredictability
    return _pickFromTopMoves(scores, 3);
  }

  /// Impossible: Minimax with alpha-beta pruning, 5-ply depth
  Position _getImpossibleMove(GameState state, List<Position> validMoves) {
    final scores = <Position, double>{};
    const depth = 5;

    for (final move in validMoves) {
      final newState = _simulateMove(state, move);
      final score = _minimax(
        newState,
        depth - 1,
        double.negativeInfinity,
        double.infinity,
        false, // Now it's opponent's turn (minimizing)
        state.currentPlayer,
      );
      scores[move] = score + _random.nextDouble() * 0.1; // Tiny randomness for ties
    }

    return _pickFromTopMoves(scores, 2);
  }

  /// Minimax algorithm with alpha-beta pruning
  double _minimax(
    GameState state,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
    Player aiPlayer,
  ) {
    // Terminal conditions
    if (state.result == GameResult.player1Wins) {
      return aiPlayer == Player.player1 ? 1000 : -1000;
    }
    if (state.result == GameResult.player2Wins) {
      return aiPlayer == Player.player2 ? 1000 : -1000;
    }

    final validMoves = state.getValidMoves();
    
    // Check for trap condition
    if (validMoves.isEmpty) {
      // Current player is trapped, so the previous player wins
      final winner = state.currentPlayer.opponent;
      return winner == aiPlayer ? 1000 : -1000;
    }

    if (depth == 0) {
      return _evaluate(state, aiPlayer);
    }

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (final move in validMoves) {
        final newState = _simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false, aiPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // Prune
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (final move in validMoves) {
        final newState = _simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true, aiPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break; // Prune
      }
      return minEval;
    }
  }

  /// Evaluation function for non-terminal states
  double _evaluate(GameState state, Player aiPlayer) {
    double score = 0;

    // Mobility score
    final currentMoves = state.getValidMoves().length;
    final opponentState = state.copyWith(currentPlayer: state.currentPlayer.opponent);
    final opponentMoves = opponentState.getValidMoves().length;

    if (state.currentPlayer == aiPlayer) {
      score += currentMoves * 10;
      score -= opponentMoves * 10;
    } else {
      score += opponentMoves * 10;
      score -= currentMoves * 10;
    }

    // Center control bonus (prefer positions closer to center)
    final aiPos = state.getPlayerPosition(aiPlayer);
    final center = state.gridSize / 2;
    final distToCenter = (aiPos.row - center).abs() + (aiPos.col - center).abs();
    score += (state.gridSize - distToCenter) * 2;

    return score;
  }

  /// Simulate a move and return the resulting state (simplified, no animations)
  GameState _simulateMove(GameState state, Position target) {
    final currentPos = state.getPlayerPosition(state.currentPlayer);
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);

    // Create new board with the origin tile set to void
    final newBoard = state.copyBoard();
    newBoard[currentPos.row][currentPos.col] = const TileState(status: TileStatus.void_);

    // Update player position
    final Position newP1Pos;
    final Position newP2Pos;

    if (state.currentPlayer == Player.player1) {
      newP1Pos = target;
      newP2Pos = state.player2Position;
    } else {
      newP1Pos = state.player1Position;
      newP2Pos = target;
    }

    // Check for capture win
    GameResult result = GameResult.ongoing;
    if (target == opponentPos) {
      result = state.currentPlayer == Player.player1
          ? GameResult.player1Wins
          : GameResult.player2Wins;
    }

    // Create new state with switched player
    final newState = state.copyWith(
      board: newBoard,
      player1Position: newP1Pos,
      player2Position: newP2Pos,
      currentPlayer: state.currentPlayer.opponent,
      result: result,
      moveCount: state.moveCount + 1,
    );

    // Check if next player is trapped
    if (result == GameResult.ongoing && newState.getValidMoves().isEmpty) {
      return newState.copyWith(
        result: state.currentPlayer == Player.player1
            ? GameResult.player1Wins
            : GameResult.player2Wins,
      );
    }

    return newState;
  }

  /// Count valid moves from a specific position (for mobility calculation)
  int _countValidMovesFromPosition(GameState state, Position pos) {
    final potentialMoves = pos.getKnightMoves(state.gridSize);
    return potentialMoves.where((p) {
      if (!p.isOnBoard(state.gridSize)) return false;
      if (!state.board[p.row][p.col].isPlayable) return false;
      return true;
    }).length;
  }

  /// Pick the move with highest score
  Position _pickBestMove(Map<Position, double> scores) {
    Position? best;
    double bestScore = double.negativeInfinity;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        best = entry.key;
      }
    }
    return best!;
  }

  /// Pick randomly from top N scoring moves
  Position _pickFromTopMoves(Map<Position, double> scores, int topN) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final candidates = sorted.take(min(topN, sorted.length)).toList();
    return candidates[_random.nextInt(candidates.length)].key;
  }
}

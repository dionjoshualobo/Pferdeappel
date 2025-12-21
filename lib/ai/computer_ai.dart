import 'dart:math';
import '../models/models.dart';

/// Enhanced AI engine with improved heuristics and deeper search
class ComputerAI {
  final Random _random = Random();
  
  // Transposition table for caching evaluated positions
  final Map<String, double> _transpositionTable = {};

  /// Get the best move for the current player based on difficulty
  Position? getBestMove(GameState state, Difficulty difficulty) {
    final validMoves = state.getValidMoves();
    if (validMoves.isEmpty) return null;

    // Clear transposition table for each new decision
    _transpositionTable.clear();

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

  /// Easy: Pick a random valid move (occasionally avoid obvious traps)
  Position _getEasyMove(List<Position> validMoves) {
    // 70% chance of pure random, 30% chance of avoiding worst move
    if (_random.nextDouble() < 0.7 || validMoves.length == 1) {
      return validMoves[_random.nextInt(validMoves.length)];
    }
    
    // Avoid the first move in list (which might be predictable)
    final shuffled = List<Position>.from(validMoves)..shuffle(_random);
    return shuffled.first;
  }

  /// Medium: Avoid captures, prefer high mobility, aggressive when possible
  Position _getMediumMove(GameState state, List<Position> validMoves) {
    final scores = <Position, double>{};
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);

    for (final move in validMoves) {
      double score = 0;

      // Immediate win - always take it
      if (move == opponentPos && _canCapture(state)) {
        return move;
      }

      // Simulate the move
      final simState = _simulateMove(state, move);
      
      // Check if opponent is trapped (we win)
      if (simState.getValidMoves().isEmpty) {
        return move;
      }

      final opponentMoves = simState.getValidMoves();

      // Heavily penalize moves where opponent can capture us
      if (opponentMoves.contains(move)) {
        score -= 100;
      }

      // Our mobility after this move
      final ourFutureMobility = _countMobilityAfterMove(state, move);
      score += ourFutureMobility * 8;

      // Opponent's mobility after this move (lower is better for us)
      score -= opponentMoves.length * 5;
      
      // Bonus for reducing opponent to few moves
      if (opponentMoves.length <= 2) {
        score += 30;
      }
      if (opponentMoves.length == 1) {
        score += 50;
      }

      // Small randomness
      score += _random.nextDouble() * 5;

      scores[move] = score;
    }

    return _pickBestMove(scores);
  }

  /// Hard: 4-ply lookahead with improved evaluation
  Position _getHardMove(GameState state, List<Position> validMoves) {
    final scores = <Position, double>{};
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    const depth = 4;

    // Check for immediate wins first
    for (final move in validMoves) {
      if (move == opponentPos && _canCapture(state)) {
        return move;
      }
      final simState = _simulateMove(state, move);
      if (simState.result != GameResult.ongoing) {
        return move;
      }
    }

    // Order moves by quick evaluation (improves pruning)
    final orderedMoves = _orderMoves(state, validMoves);

    for (final move in orderedMoves) {
      final newState = _simulateMove(state, move);
      final score = _minimax(
        newState,
        depth - 1,
        double.negativeInfinity,
        double.infinity,
        false,
        state.currentPlayer,
      );
      scores[move] = score + _random.nextDouble() * 2; // Small randomness for variety
    }

    return _pickFromTopMoves(scores, 2);
  }

  /// Impossible: Deep Minimax with enhanced evaluation and iterative deepening
  Position _getImpossibleMove(GameState state, List<Position> validMoves) {
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);

    // Check for immediate wins
    for (final move in validMoves) {
      if (move == opponentPos && _canCapture(state)) {
        return move;
      }
      final simState = _simulateMove(state, move);
      if (simState.result != GameResult.ongoing) {
        return move;
      }
    }

    // Adaptive depth based on number of valid moves and board size
    // Fewer moves = can search deeper
    final baseDepth = 7;
    final moveCountFactor = validMoves.length <= 3 ? 2 : (validMoves.length <= 5 ? 1 : 0);
    final depth = baseDepth + moveCountFactor;

    final scores = <Position, double>{};
    
    // Order moves for better pruning
    final orderedMoves = _orderMoves(state, validMoves);

    for (final move in orderedMoves) {
      final newState = _simulateMove(state, move);
      final score = _minimax(
        newState,
        depth - 1,
        double.negativeInfinity,
        double.infinity,
        false,
        state.currentPlayer,
      );
      scores[move] = score;
    }

    // Pick the absolute best move (minimal randomness)
    return _pickBestMove(scores);
  }

  /// Order moves by quick heuristic evaluation for better alpha-beta pruning
  List<Position> _orderMoves(GameState state, List<Position> moves) {
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    final scored = moves.map((move) {
      double priority = 0;
      
      // Capturing moves first
      if (move == opponentPos && _canCapture(state)) {
        priority += 1000;
      }
      
      // Moves that trap opponent
      final simState = _simulateMove(state, move);
      if (simState.result != GameResult.ongoing) {
        priority += 900;
      }
      
      // Moves that reduce opponent mobility
      final oppMoves = simState.getValidMoves().length;
      priority += (10 - oppMoves) * 10;
      
      // Avoid moves where we can be captured
      if (simState.getValidMoves().contains(move)) {
        priority -= 500;
      }
      
      return MapEntry(move, priority);
    }).toList();
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Enhanced Minimax with alpha-beta pruning and transposition table
  double _minimax(
    GameState state,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
    Player aiPlayer,
  ) {
    // Check transposition table
    final stateKey = _getStateKey(state, depth, isMaximizing);
    if (_transpositionTable.containsKey(stateKey)) {
      return _transpositionTable[stateKey]!;
    }

    // Terminal conditions - check game result
    if (state.result == GameResult.player1Wins) {
      final score = aiPlayer == Player.player1 ? 10000.0 : -10000.0;
      return score;
    }
    if (state.result == GameResult.player2Wins) {
      final score = aiPlayer == Player.player2 ? 10000.0 : -10000.0;
      return score;
    }

    final validMoves = state.getValidMoves();
    
    // Current player is trapped
    if (validMoves.isEmpty) {
      final winner = state.currentPlayer.opponent;
      final score = winner == aiPlayer ? 10000.0 : -10000.0;
      return score;
    }

    // Leaf node - evaluate
    if (depth == 0) {
      final score = _evaluate(state, aiPlayer);
      _transpositionTable[stateKey] = score;
      return score;
    }

    // Order moves for better pruning (only at higher depths to save time)
    final moves = depth >= 3 ? _orderMoves(state, validMoves) : validMoves;

    double result;
    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (final move in moves) {
        final newState = _simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false, aiPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      result = maxEval;
    } else {
      double minEval = double.infinity;
      for (final move in moves) {
        final newState = _simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true, aiPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      result = minEval;
    }

    _transpositionTable[stateKey] = result;
    return result;
  }

  /// Generate unique key for transposition table
  String _getStateKey(GameState state, int depth, bool isMaximizing) {
    final boardKey = state.board.map((row) => 
      row.map((t) => t.status.index.toString()).join()
    ).join('|');
    return '$boardKey:${state.player1Position}:${state.player2Position}:${state.currentPlayer.index}:$depth:$isMaximizing';
  }

  /// Enhanced evaluation function with multiple heuristics
  double _evaluate(GameState state, Player aiPlayer) {
    double score = 0;
    
    final aiPos = state.getPlayerPosition(aiPlayer);
    final oppPos = state.getPlayerPosition(aiPlayer.opponent);
    
    // Calculate mobility for both players
    final aiMobility = _countMobilityFromPosition(state, aiPos);
    final oppMobility = _countMobilityFromPosition(state, oppPos);

    // === MOBILITY DIFFERENTIAL (most important) ===
    // Having more moves than opponent is critical
    score += (aiMobility - oppMobility) * 25;
    
    // === TRAP DETECTION ===
    // Severely penalize having few moves (danger zone)
    if (aiMobility == 0) {
      score -= 5000; // We're trapped
    } else if (aiMobility == 1) {
      score -= 200; // Very dangerous
    } else if (aiMobility == 2) {
      score -= 50; // Risky
    }
    
    // Reward reducing opponent to few moves
    if (oppMobility == 0) {
      score += 5000; // Opponent trapped
    } else if (oppMobility == 1) {
      score += 300; // Opponent in danger
    } else if (oppMobility == 2) {
      score += 100; // Opponent has limited options
    }

    // === CAPTURE POTENTIAL ===
    // Can we reach opponent? (Distance in knight moves)
    final canReachOpponent = aiPos.getKnightMoves(state.gridSize).contains(oppPos);
    if (canReachOpponent && _canCaptureAsPlayer(state, aiPlayer)) {
      score += 500; // Capture threat
    }
    
    // Can opponent reach us?
    final canBeReached = oppPos.getKnightMoves(state.gridSize).contains(aiPos);
    if (canBeReached) {
      score -= 150; // We're in danger
    }

    // === BOARD CONTROL ===
    // Count safe tiles we can access vs opponent
    final aiAccessibleTiles = _countAccessibleTiles(state, aiPos, 2);
    final oppAccessibleTiles = _countAccessibleTiles(state, oppPos, 2);
    score += (aiAccessibleTiles - oppAccessibleTiles) * 5;

    // === EDGE AVOIDANCE ===
    // Penalize being on edges (fewer escape routes)
    final edgePenalty = _getEdgePenalty(aiPos, state.gridSize);
    score -= edgePenalty * 8;
    
    // Reward opponent being on edge
    final oppEdgePenalty = _getEdgePenalty(oppPos, state.gridSize);
    score += oppEdgePenalty * 5;

    // === CENTER PROXIMITY (early game bonus) ===
    if (state.moveCount < 10) {
      final center = state.gridSize / 2.0;
      final aiDistToCenter = (aiPos.row - center).abs() + (aiPos.col - center).abs();
      final oppDistToCenter = (oppPos.row - center).abs() + (oppPos.col - center).abs();
      score += (oppDistToCenter - aiDistToCenter) * 3;
    }

    return score;
  }

  /// Count mobility from a specific position
  int _countMobilityFromPosition(GameState state, Position pos) {
    final potentialMoves = pos.getKnightMoves(state.gridSize);
    return potentialMoves.where((p) {
      if (!p.isOnBoard(state.gridSize)) return false;
      if (!state.board[p.row][p.col].isPlayable) return false;
      return true;
    }).length;
  }

  /// Count our mobility after making a move
  int _countMobilityAfterMove(GameState state, Position move) {
    final simState = _simulateMove(state, move);
    // Switch back to check our moves from new position
    return _countMobilityFromPosition(
      simState.copyWith(currentPlayer: state.currentPlayer),
      move,
    );
  }

  /// Count tiles accessible within N moves
  int _countAccessibleTiles(GameState state, Position start, int depth) {
    final visited = <String>{};
    final queue = [MapEntry(start, 0)];
    visited.add('${start.row},${start.col}');
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current.value >= depth) continue;
      
      for (final next in current.key.getKnightMoves(state.gridSize)) {
        final key = '${next.row},${next.col}';
        if (!visited.contains(key) && 
            next.isOnBoard(state.gridSize) &&
            state.board[next.row][next.col].isPlayable) {
          visited.add(key);
          queue.add(MapEntry(next, current.value + 1));
        }
      }
    }
    
    return visited.length;
  }

  /// Calculate edge penalty (0 for center, higher for edges/corners)
  double _getEdgePenalty(Position pos, int gridSize) {
    double penalty = 0;
    
    // Distance from edges
    final distFromTop = pos.row;
    final distFromBottom = gridSize - 1 - pos.row;
    final distFromLeft = pos.col;
    final distFromRight = gridSize - 1 - pos.col;
    
    // Penalize being close to edges
    if (distFromTop == 0 || distFromBottom == 0) penalty += 2;
    if (distFromLeft == 0 || distFromRight == 0) penalty += 2;
    
    // Extra penalty for corners
    if ((distFromTop == 0 || distFromBottom == 0) && 
        (distFromLeft == 0 || distFromRight == 0)) {
      penalty += 3;
    }
    
    return penalty;
  }

  /// Check if current player can capture (respects 4x4 first move rule)
  bool _canCapture(GameState state) {
    return !state.isPlayer2FirstMove;
  }

  /// Check if a specific player can capture
  bool _canCaptureAsPlayer(GameState state, Player player) {
    if (player == Player.player2 && state.moveCount == 1) {
      return false; // 4x4 rule
    }
    return true;
  }

  /// Simulate a move and return the resulting state
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
    if (target == opponentPos && _canCapture(state)) {
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

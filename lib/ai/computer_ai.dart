import 'dart:math';
import '../models/models.dart';

/// Enhanced AI engine with deterministic best-move selection
class ComputerAI {
  final Random _random = Random();
  
  // Transposition table for caching
  final Map<String, _TranspositionEntry> _transpositionTable = {};

  /// Get the best move for the current player based on difficulty
  Position? getBestMove(GameState state, Difficulty difficulty) {
    final validMoves = state.getValidMoves();
    if (validMoves.isEmpty) return null;
    if (validMoves.length == 1) return validMoves.first;

    // Clear transposition table for fresh evaluation
    _transpositionTable.clear();

    // ALWAYS check for immediate winning moves first (all difficulties)
    final immediateWin = _findImmediateWin(state, validMoves);
    if (immediateWin != null) return immediateWin;

    switch (difficulty) {
      case Difficulty.easy:
        return _getEasyMove(state, validMoves);
      case Difficulty.medium:
        return _getMediumMove(state, validMoves);
      case Difficulty.hard:
        return _getHardMove(state, validMoves);
      case Difficulty.impossible:
        return _getImpossibleMove(state, validMoves);
    }
  }

  /// Find immediate winning move (capture or trap)
  Position? _findImmediateWin(GameState state, List<Position> validMoves) {
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    for (final move in validMoves) {
      // Check capture
      if (move == opponentPos && _canCapture(state)) {
        return move;
      }
      
      // Check if this move traps opponent
      final simState = _simulateMove(state, move);
      if (simState.result != GameResult.ongoing) {
        return move;
      }
      
      // Also check if opponent has 0 moves (trap)
      if (simState.getValidMoves().isEmpty) {
        return move;
      }
    }
    return null;
  }

  /// Easy: Random with some basic avoidance
  Position _getEasyMove(GameState state, List<Position> validMoves) {
    // Shuffle and pick, but avoid moves where we get captured immediately
    final shuffled = List<Position>.from(validMoves)..shuffle(_random);
    
    for (final move in shuffled) {
      final simState = _simulateMove(state, move);
      final oppMoves = simState.getValidMoves();
      // Avoid getting captured next turn (30% of the time even pick bad moves for easy)
      if (!oppMoves.contains(move) || _random.nextDouble() < 0.3) {
        return move;
      }
    }
    return shuffled.first;
  }

  /// Medium: Heuristic-based with 2-ply lookahead
  Position _getMediumMove(GameState state, List<Position> validMoves) {
    final scores = <Position, double>{};
    
    for (final move in validMoves) {
      scores[move] = _evaluateMoveQuick(state, move);
    }
    
    return _pickBestWithTiebreaker(scores);
  }

  /// Hard: 4-ply Minimax
  Position _getHardMove(GameState state, List<Position> validMoves) {
    const depth = 4;
    return _searchBestMove(state, validMoves, depth);
  }

  /// Impossible: Deep adaptive Minimax - must win
  Position _getImpossibleMove(GameState state, List<Position> validMoves) {
    // Adaptive depth based on board state
    // Smaller boards and fewer moves = search deeper
    final gridSize = state.gridSize;
    final moveCount = validMoves.length;
    
    int depth;
    if (gridSize <= 4) {
      // Small board: search very deep
      depth = moveCount <= 3 ? 12 : (moveCount <= 5 ? 10 : 8);
    } else if (gridSize <= 6) {
      depth = moveCount <= 3 ? 10 : (moveCount <= 5 ? 8 : 7);
    } else {
      // Larger boards
      depth = moveCount <= 3 ? 9 : (moveCount <= 5 ? 7 : 6);
    }
    
    // Early game on large boards: add some randomness to first move only
    if (state.moveCount == 0 && gridSize >= 6) {
      // First move on large board: pick randomly from good moves
      final scores = <Position, double>{};
      for (final move in validMoves) {
        scores[move] = _evaluateMoveQuick(state, move);
      }
      // Pick from top 50% of moves
      final sorted = scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topHalf = sorted.take((sorted.length / 2).ceil()).toList();
      return topHalf[_random.nextInt(topHalf.length)].key;
    }
    
    return _searchBestMove(state, validMoves, depth);
  }

  /// Core search function using Minimax with alpha-beta pruning
  Position _searchBestMove(GameState state, List<Position> validMoves, int depth) {
    final scores = <Position, double>{};
    final aiPlayer = state.currentPlayer;
    
    // Order moves for better pruning
    final orderedMoves = _orderMovesByPotential(state, validMoves);
    
    double alpha = double.negativeInfinity;
    final beta = double.infinity;
    
    for (final move in orderedMoves) {
      final newState = _simulateMove(state, move);
      
      // Check for immediate win from this move
      if (newState.result != GameResult.ongoing) {
        final isWin = (newState.result == GameResult.player1Wins && aiPlayer == Player.player1) ||
                      (newState.result == GameResult.player2Wins && aiPlayer == Player.player2);
        if (isWin) {
          return move; // Immediate win - take it
        }
      }
      
      final score = _minimax(
        newState,
        depth - 1,
        alpha,
        beta,
        false, // Opponent's turn (minimizing)
        aiPlayer,
      );
      
      scores[move] = score;
      alpha = max(alpha, score);
    }
    
    return _pickBestWithTiebreaker(scores);
  }

  /// Quick move evaluation for ordering and medium difficulty
  double _evaluateMoveQuick(GameState state, Position move) {
    double score = 0;
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    // Immediate trap?
    final simState = _simulateMove(state, move);
    final oppMoves = simState.getValidMoves();
    
    if (oppMoves.isEmpty) {
      score += 10000; // We win
    } else if (oppMoves.length == 1) {
      score += 500; // Opponent nearly trapped
    } else if (oppMoves.length == 2) {
      score += 200;
    }
    
    // Can opponent capture us?
    if (oppMoves.contains(move)) {
      score -= 800; // Very bad
    }
    
    // Our mobility after this move
    final ourMobility = _countMobilityAfterMove(state, move);
    score += ourMobility * 30;
    
    // Reduce opponent mobility
    score -= oppMoves.length * 25;
    
    // Capture threat
    if (move == opponentPos && _canCapture(state)) {
      score += 10000;
    }
    
    // Edge penalty for us
    score -= _getEdgePenalty(move, state.gridSize) * 15;
    
    return score;
  }

  /// Order moves by quick evaluation for better pruning
  List<Position> _orderMovesByPotential(GameState state, List<Position> moves) {
    final scored = moves.map((m) => MapEntry(m, _evaluateMoveQuick(state, m))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Minimax with alpha-beta pruning and transposition table
  double _minimax(
    GameState state,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
    Player aiPlayer,
  ) {
    // Check transposition table
    final stateKey = _getStateKey(state);
    final cached = _transpositionTable[stateKey];
    if (cached != null && cached.depth >= depth) {
      if (cached.flag == _NodeType.exact) return cached.value;
      if (cached.flag == _NodeType.lowerBound) alpha = max(alpha, cached.value);
      if (cached.flag == _NodeType.upperBound) beta = min(beta, cached.value);
      if (alpha >= beta) return cached.value;
    }

    // Terminal: game over
    if (state.result == GameResult.player1Wins) {
      return aiPlayer == Player.player1 ? 100000.0 - (100 - depth) : -100000.0 + (100 - depth);
    }
    if (state.result == GameResult.player2Wins) {
      return aiPlayer == Player.player2 ? 100000.0 - (100 - depth) : -100000.0 + (100 - depth);
    }

    final validMoves = state.getValidMoves();
    
    // Terminal: current player trapped
    if (validMoves.isEmpty) {
      final winner = state.currentPlayer.opponent;
      return winner == aiPlayer ? 100000.0 - (100 - depth) : -100000.0 + (100 - depth);
    }

    // Leaf node
    if (depth <= 0) {
      final score = _evaluate(state, aiPlayer);
      _transpositionTable[stateKey] = _TranspositionEntry(score, depth, _NodeType.exact);
      return score;
    }

    // Order moves at higher depths
    final moves = depth >= 2 ? _orderMovesByPotential(state, validMoves) : validMoves;

    double value;
    _NodeType flag;
    
    if (isMaximizing) {
      value = double.negativeInfinity;
      flag = _NodeType.upperBound;
      
      for (final move in moves) {
        final newState = _simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false, aiPlayer);
        
        if (eval > value) {
          value = eval;
          flag = _NodeType.exact;
        }
        alpha = max(alpha, eval);
        if (beta <= alpha) {
          flag = _NodeType.lowerBound;
          break;
        }
      }
    } else {
      value = double.infinity;
      flag = _NodeType.lowerBound;
      
      for (final move in moves) {
        final newState = _simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true, aiPlayer);
        
        if (eval < value) {
          value = eval;
          flag = _NodeType.exact;
        }
        beta = min(beta, eval);
        if (beta <= alpha) {
          flag = _NodeType.upperBound;
          break;
        }
      }
    }

    _transpositionTable[stateKey] = _TranspositionEntry(value, depth, flag);
    return value;
  }

  /// Generate state key for transposition table
  String _getStateKey(GameState state) {
    final buffer = StringBuffer();
    for (int r = 0; r < state.gridSize; r++) {
      for (int c = 0; c < state.gridSize; c++) {
        buffer.write(state.board[r][c].status.index);
      }
    }
    buffer.write(':${state.player1Position.row},${state.player1Position.col}');
    buffer.write(':${state.player2Position.row},${state.player2Position.col}');
    buffer.write(':${state.currentPlayer.index}');
    return buffer.toString();
  }

  /// Comprehensive evaluation function
  double _evaluate(GameState state, Player aiPlayer) {
    final aiPos = state.getPlayerPosition(aiPlayer);
    final oppPos = state.getPlayerPosition(aiPlayer.opponent);
    
    final aiMobility = _countMobilityFromPosition(state, aiPos);
    final oppMobility = _countMobilityFromPosition(state, oppPos);

    double score = 0;

    // === CRITICAL: Trap detection ===
    if (aiMobility == 0) return -50000; // We're trapped
    if (oppMobility == 0) return 50000;  // Opponent trapped
    
    // Near-trap states
    if (aiMobility == 1) {
      score -= 2000;
    } else if (aiMobility == 2) {
      score -= 500;
    }
    
    if (oppMobility == 1) {
      score += 3000;
    } else if (oppMobility == 2) {
      score += 1000;
    } else if (oppMobility == 3) {
      score += 300;
    }

    // === Mobility differential ===
    score += (aiMobility - oppMobility) * 100;

    // === Capture potential ===
    final canCaptureOpp = aiPos.getKnightMoves(state.gridSize).contains(oppPos);
    if (canCaptureOpp && _canCaptureAsPlayer(state, aiPlayer)) {
      score += 2000;
    }
    
    final canBeCaptured = oppPos.getKnightMoves(state.gridSize).contains(aiPos);
    if (canBeCaptured) {
      score -= 1500;
    }

    // === Board territory ===
    final aiTerritory = _countAccessibleTiles(state, aiPos, 2);
    final oppTerritory = _countAccessibleTiles(state, oppPos, 2);
    score += (aiTerritory - oppTerritory) * 20;

    // === Edge avoidance ===
    score -= _getEdgePenalty(aiPos, state.gridSize) * 50;
    score += _getEdgePenalty(oppPos, state.gridSize) * 30;

    // === Center control (early game) ===
    if (state.moveCount < 8) {
      final center = state.gridSize / 2.0;
      final aiDist = (aiPos.row - center).abs() + (aiPos.col - center).abs();
      final oppDist = (oppPos.row - center).abs() + (oppPos.col - center).abs();
      score += (oppDist - aiDist) * 15;
    }

    return score;
  }
  
  // === Helper methods ===

  int _countMobilityFromPosition(GameState state, Position pos) {
    return pos.getKnightMoves(state.gridSize).where((p) {
      if (!p.isOnBoard(state.gridSize)) return false;
      return state.board[p.row][p.col].isPlayable;
    }).length;
  }

  int _countMobilityAfterMove(GameState state, Position move) {
    final simState = _simulateMove(state, move);
    return _countMobilityFromPosition(
      simState.copyWith(currentPlayer: state.currentPlayer),
      move,
    );
  }

  int _countAccessibleTiles(GameState state, Position start, int maxDepth) {
    final visited = <String>{};
    final queue = [MapEntry(start, 0)];
    visited.add('${start.row},${start.col}');
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current.value >= maxDepth) continue;
      
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

  double _getEdgePenalty(Position pos, int gridSize) {
    double penalty = 0;
    if (pos.row == 0 || pos.row == gridSize - 1) penalty += 2;
    if (pos.col == 0 || pos.col == gridSize - 1) penalty += 2;
    // Corner extra penalty
    if ((pos.row == 0 || pos.row == gridSize - 1) && 
        (pos.col == 0 || pos.col == gridSize - 1)) {
      penalty += 3;
    }
    return penalty;
  }

  bool _canCapture(GameState state) => !state.isPlayer2FirstMove;
  
  bool _canCaptureAsPlayer(GameState state, Player player) {
    return !(player == Player.player2 && state.moveCount == 1);
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

    // Check trap
    if (result == GameResult.ongoing && newState.getValidMoves().isEmpty) {
      return newState.copyWith(
        result: state.currentPlayer == Player.player1
            ? GameResult.player1Wins
            : GameResult.player2Wins,
      );
    }

    return newState;
  }

  /// Pick best move, with tiebreaker for equal scores
  Position _pickBestWithTiebreaker(Map<Position, double> scores) {
    if (scores.isEmpty) throw StateError('No moves to pick from');
    
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final bestScore = sorted.first.value;
    
    // Find all moves with the same best score (within tiny epsilon)
    final bestMoves = sorted.where((e) => (e.value - bestScore).abs() < 0.001).toList();
    
    // If only one best move, return it deterministically
    if (bestMoves.length == 1) {
      return bestMoves.first.key;
    }
    
    // Multiple equal best moves: pick randomly among them
    return bestMoves[_random.nextInt(bestMoves.length)].key;
  }
}

/// Transposition table entry
class _TranspositionEntry {
  final double value;
  final int depth;
  final _NodeType flag;
  
  _TranspositionEntry(this.value, this.depth, this.flag);
}

enum _NodeType { exact, lowerBound, upperBound }

import 'dart:math' show max;
import '../../models/models.dart';
import 'ai_strategy.dart';

/// Impossible AI: Deep Minimax with iterative deepening
/// This strategy uses maximum search depth and aggressive evaluation
class ImpossibleStrategy with AIUtilities implements AIStrategy {
  final Map<String, _CacheEntry> _cache = {};
  
  @override
  String get name => 'Impossible';
  
  @override
  Position? getBestMove(GameState state) {
    final moves = state.getValidMoves();
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;
    
    // Clear cache for fresh evaluation
    _cache.clear();
    
    // CRITICAL: Always check for immediate wins FIRST
    final win = findImmediateWin(state, moves);
    if (win != null) {
      return win;
    }
    
    // Check for moves that leave opponent with only 1 option
    final trapMove = _findNearTrapMove(state, moves);
    if (trapMove != null) {
      return trapMove;
    }
    
    // Calculate search depth based on game state
    final depth = _calculateDepth(state, moves.length);
    
    // Search for best move
    final scores = <Position, double>{};
    final aiPlayer = state.currentPlayer;
    
    // Order moves by quick evaluation for better pruning
    final orderedMoves = _orderMoves(state, moves);
    
    double alpha = double.negativeInfinity;
    const beta = double.infinity;
    
    for (final move in orderedMoves) {
      final newState = simulateMove(state, move);
      final score = _negamax(newState, depth - 1, -beta, -alpha, -1, aiPlayer);
      scores[move] = -score;
      alpha = max(alpha, -score);
    }
    
    // Pick the absolute best move
    return _pickAbsoluteBest(scores);
  }
  
  /// Find a move that leaves opponent with only 1 move
  Position? _findNearTrapMove(GameState state, List<Position> moves) {
    for (final move in moves) {
      final simState = simulateMove(state, move);
      final oppMoves = simState.getValidMoves();
      if (oppMoves.length == 1) {
        // Check if that single move doesn't save them
        final afterOpp = simulateMove(simState, oppMoves.first);
        if (afterOpp.getValidMoves().isEmpty) {
          return move; // This leads to guaranteed trap
        }
      }
    }
    return null;
  }
  
  /// Calculate search depth based on game state
  int _calculateDepth(GameState state, int numMoves) {
    final gridSize = state.gridSize;
    
    // Base depth depends on board size
    int base;
    if (gridSize <= 4) {
      base = 15; // Very deep for small boards
    } else if (gridSize <= 6) {
      base = 10;
    } else {
      base = 8;
    }
    
    // Fewer moves = can search deeper
    if (numMoves <= 2) {
      base += 4;
    } else if (numMoves <= 4) {
      base += 2;
    } else if (numMoves >= 8) {
      base -= 2;
    }
    
    // Late game = search deeper
    final playedTiles = _countVoidTiles(state);
    if (playedTiles > gridSize * gridSize / 2) {
      base += 2;
    }
    
    return base;
  }
  
  int _countVoidTiles(GameState state) {
    int count = 0;
    for (int r = 0; r < state.gridSize; r++) {
      for (int c = 0; c < state.gridSize; c++) {
        if (state.board[r][c].status == TileStatus.void_) {
          count++;
        }
      }
    }
    return count;
  }
  
  /// Order moves by quick heuristic for better pruning
  List<Position> _orderMoves(GameState state, List<Position> moves) {
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    final scored = <MapEntry<Position, double>>[];
    for (final move in moves) {
      double priority = 0;
      
      // Capture first
      if (move == opponentPos && canCapture(state)) {
        priority += 10000;
      }
      
      final simState = simulateMove(state, move);
      final oppMoves = simState.getValidMoves();
      
      // Trap opponent
      if (oppMoves.isEmpty) priority += 9000;
      
      // Near-trap
      if (oppMoves.length == 1) priority += 5000;
      if (oppMoves.length == 2) priority += 2000;
      
      // Avoid being captured
      if (oppMoves.contains(move)) priority -= 4000;
      
      // Our mobility
      final ourMob = countMobility(simState.copyWith(currentPlayer: state.currentPlayer), move);
      priority += ourMob * 100;
      
      // Reduce opponent mobility
      priority -= oppMoves.length * 80;
      
      scored.add(MapEntry(move, priority));
    }
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
  
  /// Negamax search with alpha-beta pruning
  double _negamax(GameState state, int depth, double alpha, double beta, 
                  int color, Player aiPlayer) {
    // Check cache
    final key = _stateKey(state, depth);
    if (_cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (entry.depth >= depth) {
        if (entry.flag == _Flag.exact) return entry.value * color;
        if (entry.flag == _Flag.lower && entry.value >= beta) return entry.value * color;
        if (entry.flag == _Flag.upper && entry.value <= alpha) return entry.value * color;
      }
    }
    
    // Terminal: game over
    if (state.result != GameResult.ongoing) {
      if (state.result == GameResult.player1Wins) {
        return (aiPlayer == Player.player1 ? 100000.0 : -100000.0) * color;
      }
      return (aiPlayer == Player.player2 ? 100000.0 : -100000.0) * color;
    }
    
    final moves = state.getValidMoves();
    
    // Terminal: trapped
    if (moves.isEmpty) {
      final winner = state.currentPlayer.opponent;
      return (winner == aiPlayer ? 100000.0 : -100000.0) * color;
    }
    
    // Leaf node
    if (depth <= 0) {
      return _evaluate(state, aiPlayer) * color;
    }
    
    // Order moves for better pruning
    final orderedMoves = depth >= 3 ? _orderMoves(state, moves) : moves;
    
    double value = double.negativeInfinity;
    _Flag flag = _Flag.upper;
    
    for (final move in orderedMoves) {
      final newState = simulateMove(state, move);
      final score = -_negamax(newState, depth - 1, -beta, -alpha, -color, aiPlayer);
      
      if (score > value) {
        value = score;
        flag = _Flag.exact;
      }
      
      alpha = max(alpha, score);
      if (alpha >= beta) {
        flag = _Flag.lower;
        break;
      }
    }
    
    _cache[key] = _CacheEntry(value, depth, flag);
    return value;
  }
  
  String _stateKey(GameState state, int depth) {
    final sb = StringBuffer();
    for (int r = 0; r < state.gridSize; r++) {
      for (int c = 0; c < state.gridSize; c++) {
        sb.write(state.board[r][c].status.index);
      }
    }
    sb.write('|${state.player1Position.row},${state.player1Position.col}');
    sb.write('|${state.player2Position.row},${state.player2Position.col}');
    sb.write('|${state.currentPlayer.index}|$depth');
    return sb.toString();
  }
  
  /// Comprehensive evaluation function
  double _evaluate(GameState state, Player aiPlayer) {
    final aiPos = state.getPlayerPosition(aiPlayer);
    final oppPos = state.getPlayerPosition(aiPlayer.opponent);
    
    final aiMob = countMobility(state, aiPos);
    final oppMob = countMobility(state, oppPos);
    
    // Critical trap detection
    if (aiMob == 0) return -50000;
    if (oppMob == 0) return 50000;
    
    double score = 0;
    
    // Mobility is CRITICAL
    score += (aiMob - oppMob) * 200;
    
    // Near-trap situations
    if (aiMob == 1) {
      score -= 3000;
    } else if (aiMob == 2) {
      score -= 800;
    }
    
    if (oppMob == 1) {
      score += 4000;
    } else if (oppMob == 2) {
      score += 1500;
    } else if (oppMob == 3) {
      score += 500;
    }
    
    // Capture threat
    final canCaptureOpp = aiPos.getKnightMoves(state.gridSize).contains(oppPos);
    if (canCaptureOpp && !state.isPlayer2FirstMove) {
      score += 3000;
    }
    
    // Can opponent capture us?
    final inDanger = oppPos.getKnightMoves(state.gridSize).contains(aiPos);
    if (inDanger) {
      score -= 2000;
    }
    
    // Territory control (2-move reach)
    final aiTerritory = _countTerritory(state, aiPos, 2);
    final oppTerritory = _countTerritory(state, oppPos, 2);
    score += (aiTerritory - oppTerritory) * 30;
    
    // Edge penalty
    score -= getEdgePenalty(aiPos, state.gridSize) * 80;
    score += getEdgePenalty(oppPos, state.gridSize) * 50;
    
    // Center control (early game)
    if (state.moveCount < 10) {
      final center = state.gridSize / 2.0;
      final aiDist = (aiPos.row - center).abs() + (aiPos.col - center).abs();
      final oppDist = (oppPos.row - center).abs() + (oppPos.col - center).abs();
      score += (oppDist - aiDist) * 25;
    }
    
    return score;
  }
  
  int _countTerritory(GameState state, Position start, int maxDepth) {
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
  
  /// Pick the absolute best move (no randomness)
  Position _pickAbsoluteBest(Map<Position, double> scores) {
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
}

class _CacheEntry {
  final double value;
  final int depth;
  final _Flag flag;
  
  _CacheEntry(this.value, this.depth, this.flag);
}

enum _Flag { exact, lower, upper }

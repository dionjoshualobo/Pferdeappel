import 'dart:math';
import '../../models/models.dart';
import 'ai_strategy.dart';

/// Hard AI: Minimax with 5-ply depth
class HardStrategy with AIUtilities implements AIStrategy {
  final Random _random = Random();
  
  @override
  String get name => 'Hard';
  
  @override
  Position? getBestMove(GameState state) {
    final moves = state.getValidMoves();
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;
    
    // Always take immediate wins
    final win = findImmediateWin(state, moves);
    if (win != null) return win;
    
    const depth = 4; // Reduced from 5 for faster performance
    final scores = <Position, double>{};
    final aiPlayer = state.currentPlayer;
    
    for (final move in moves) {
      final newState = simulateMove(state, move);
      scores[move] = _minimax(newState, depth - 1, double.negativeInfinity, 
                              double.infinity, false, aiPlayer);
    }
    
    return _pickBest(scores);
  }
  
  double _minimax(GameState state, int depth, double alpha, double beta, 
                  bool isMaximizing, Player aiPlayer) {
    // Terminal check
    if (state.result == GameResult.player1Wins) {
      return aiPlayer == Player.player1 ? 10000 : -10000;
    }
    if (state.result == GameResult.player2Wins) {
      return aiPlayer == Player.player2 ? 10000 : -10000;
    }
    
    final moves = state.getValidMoves();
    if (moves.isEmpty) {
      final winner = state.currentPlayer.opponent;
      return winner == aiPlayer ? 10000 : -10000;
    }
    
    if (depth <= 0) {
      return _evaluate(state, aiPlayer);
    }
    
    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (final move in moves) {
        final newState = simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false, aiPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (final move in moves) {
        final newState = simulateMove(state, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true, aiPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }
  
  double _evaluate(GameState state, Player aiPlayer) {
    final aiPos = state.getPlayerPosition(aiPlayer);
    final oppPos = state.getPlayerPosition(aiPlayer.opponent);
    
    final aiMob = countMobility(state, aiPos);
    final oppMob = countMobility(state, oppPos);
    
    double score = 0;
    
    // Trap detection
    if (aiMob == 0) return -5000;
    if (oppMob == 0) return 5000;
    
    // Mobility differential
    score += (aiMob - oppMob) * 50;
    
    // Near-trap bonuses
    if (oppMob == 1) score += 500;
    if (oppMob == 2) score += 200;
    if (aiMob == 1) score -= 400;
    if (aiMob == 2) score -= 150;
    
    // Edge penalty
    score -= getEdgePenalty(aiPos, state.gridSize) * 20;
    score += getEdgePenalty(oppPos, state.gridSize) * 10;
    
    return score;
  }
  
  Position _pickBest(Map<Position, double> scores) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final best = sorted.first.value;
    final ties = sorted.where((e) => (e.value - best).abs() < 0.5).toList();
    
    return ties[_random.nextInt(ties.length)].key;
  }
}

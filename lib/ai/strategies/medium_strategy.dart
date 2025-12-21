import 'dart:math';
import '../../models/models.dart';
import 'ai_strategy.dart';

/// Medium AI: Heuristic evaluation with 2-ply lookahead
class MediumStrategy with AIUtilities implements AIStrategy {
  final Random _random = Random();
  
  @override
  String get name => 'Medium';
  
  @override
  Position? getBestMove(GameState state) {
    final moves = state.getValidMoves();
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;
    
    // Always take immediate wins
    final win = findImmediateWin(state, moves);
    if (win != null) return win;
    
    // Score each move
    final scores = <Position, double>{};
    for (final move in moves) {
      scores[move] = _evaluateMove(state, move);
    }
    
    // Pick best move (with small random tiebreaker)
    return _pickBest(scores);
  }
  
  double _evaluateMove(GameState state, Position move) {
    double score = 0;
    final simState = simulateMove(state, move);
    final oppMoves = simState.getValidMoves();
    
    // Opponent trapped = win
    if (oppMoves.isEmpty) return 10000;
    
    // Can opponent capture us?
    if (oppMoves.contains(move)) {
      score -= 500;
    }
    
    // Our mobility after move
    final ourMobility = countMobility(
      simState.copyWith(currentPlayer: state.currentPlayer), 
      move
    );
    score += ourMobility * 20;
    
    // Opponent's mobility (lower = better)
    score -= oppMoves.length * 15;
    
    // Bonus for limiting opponent
    if (oppMoves.length <= 2) score += 100;
    if (oppMoves.length == 1) score += 200;
    
    // Edge penalty
    score -= getEdgePenalty(move, state.gridSize) * 10;
    
    return score;
  }
  
  Position _pickBest(Map<Position, double> scores) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final best = sorted.first.value;
    final ties = sorted.where((e) => (e.value - best).abs() < 1).toList();
    
    return ties[_random.nextInt(ties.length)].key;
  }
}

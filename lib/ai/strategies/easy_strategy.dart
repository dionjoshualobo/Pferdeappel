import 'dart:math';
import '../../models/models.dart';
import 'ai_strategy.dart';

/// Easy AI: Random moves with basic trap avoidance
class EasyStrategy with AIUtilities implements AIStrategy {
  final Random _random = Random();
  
  @override
  String get name => 'Easy';
  
  @override
  Position? getBestMove(GameState state) {
    final moves = state.getValidMoves();
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;
    
    // Even easy mode should take obvious wins
    final win = findImmediateWin(state, moves);
    if (win != null) return win;
    
    // 70% random, 30% avoid getting captured
    if (_random.nextDouble() < 0.7) {
      return moves[_random.nextInt(moves.length)];
    }
    
    // Try to avoid moves where opponent can capture us
    final shuffled = List<Position>.from(moves)..shuffle(_random);
    for (final move in shuffled) {
      final simState = simulateMove(state, move);
      if (!simState.getValidMoves().contains(move)) {
        return move;
      }
    }
    
    return shuffled.first;
  }
}

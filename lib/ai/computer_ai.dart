import '../models/models.dart';
import 'strategies/ai_strategy.dart';
import 'strategies/easy_strategy.dart';
import 'strategies/medium_strategy.dart';
import 'strategies/hard_strategy.dart';
import 'strategies/impossible_strategy.dart';

/// Computer AI that delegates to difficulty-specific strategies
class ComputerAI {
  // Cache strategies to reuse
  static final _strategies = <Difficulty, AIStrategy>{
    Difficulty.easy: EasyStrategy(),
    Difficulty.medium: MediumStrategy(),
    Difficulty.hard: HardStrategy(),
    Difficulty.impossible: ImpossibleStrategy(),
  };

  /// Get the best move for the current player based on difficulty
  Position? getBestMove(GameState state, Difficulty difficulty) {
    final strategy = _strategies[difficulty]!;
    return strategy.getBestMove(state);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../models/tile_state.dart';
import '../models/player.dart';
import '../models/game_settings.dart';
import '../ai/computer_ai.dart';

/// Provider for the game state - this is the main provider
final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(
  GameStateNotifier.new,
);

/// Notifier that handles all game logic and state mutations
class GameStateNotifier extends Notifier<GameState> {
  GameSettings _currentSettings = const GameSettings();

  @override
  GameState build() {
    return GameState.initial(_currentSettings);
  }

  /// Get current settings
  GameSettings get settings => _currentSettings;

  /// Reset the game to initial state (keeps current settings)
  void resetGame() {
    state = GameState.initial(_currentSettings);
  }

  /// Start a new game with specific settings
  void startNewGame(GameSettings settings) {
    _currentSettings = settings;
    state = GameState.initial(settings);
  }

  /// Execute a move from current position to target
  /// Returns true if the move was successful
  bool makeMove(Position target) {
    // Validate move
    if (!state.isValidMove(target)) return false;

    final currentPos = state.getPlayerPosition(state.currentPlayer);
    final opponentPos = state.getPlayerPosition(state.currentPlayer.opponent);
    
    // Create new board with the origin tile set to falling
    final newBoard = state.copyBoard();
    newBoard[currentPos.row][currentPos.col] = const TileState(status: TileStatus.falling);

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

    // Check for capture win condition
    GameResult result = GameResult.ongoing;
    if (target == opponentPos) {
      result = state.currentPlayer == Player.player1 
          ? GameResult.player1Wins 
          : GameResult.player2Wins;
    }

    state = state.copyWith(
      board: newBoard,
      player1Position: newP1Pos,
      player2Position: newP2Pos,
      fallingTilePosition: currentPos,
      result: result,
      moveCount: state.moveCount + 1,
    );

    return true;
  }

  /// Called when tile falling animation completes
  void onTileFallComplete() {
    if (state.fallingTilePosition == null) return;

    final fallingPos = state.fallingTilePosition!;
    
    // Update the tile to void state
    final newBoard = state.copyBoard();
    newBoard[fallingPos.row][fallingPos.col] = const TileState(status: TileStatus.void_);

    // If game is already won, don't change turn
    if (state.result != GameResult.ongoing) {
      state = state.copyWith(
        board: newBoard,
        clearFallingTile: true,
      );
      return;
    }

    // Switch to next player
    final nextPlayer = state.currentPlayer.opponent;
    
    // Check if next player has any valid moves (trap condition)
    // We need to temporarily create the new state to check
    final tempState = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      clearFallingTile: true,
    );
    
    GameResult result = GameResult.ongoing;
    if (tempState.getValidMoves().isEmpty) {
      // Next player is trapped - current player wins
      result = state.currentPlayer == Player.player1 
          ? GameResult.player1Wins 
          : GameResult.player2Wins;
    }

    state = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      result: result,
      clearFallingTile: true,
    );
  }
}

/// Provider for valid moves of current player
final validMovesProvider = Provider<List<Position>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.getValidMoves();
});

/// Provider to check if game is over
final isGameOverProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.result != GameResult.ongoing;
});

/// Provider for winner (null if game ongoing)
final winnerProvider = Provider<Player?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  switch (gameState.result) {
    case GameResult.player1Wins:
      return Player.player1;
    case GameResult.player2Wins:
      return Player.player2;
    case GameResult.ongoing:
      return null;
  }
});

/// Provider to check if it's player 2's first move (capture not allowed)
final isPlayer2FirstMoveProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.isPlayer2FirstMove;
});

/// Provider to check if current player is a computer
final isComputerTurnProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState.currentPlayer.isComputer(gameState.settings);
});

/// Provider to get the computer's chosen move (null if not computer's turn or no valid moves)
final computerMoveProvider = Provider<Position?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  final isComputerTurn = ref.watch(isComputerTurnProvider);
  
  if (!isComputerTurn || gameState.result != GameResult.ongoing) {
    return null;
  }
  
  final difficulty = gameState.currentPlayer == Player.player1
      ? gameState.settings.player1Difficulty
      : gameState.settings.player2Difficulty;
  
  final ai = ComputerAI();
  return ai.getBestMove(gameState, difficulty);
});

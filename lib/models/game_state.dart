import 'position.dart';
import 'tile_state.dart';
import 'player.dart';
import 'game_settings.dart';

/// Represents the result of the game
enum GameResult {
  ongoing,
  player1Wins,
  player2Wins,
  tie,
  /// Knight's Tour specific: player completed the tour successfully
  tourComplete,
  /// Knight's Tour specific: player failed (no moves left, tour incomplete)
  tourFailed,
}

/// Complete game state
class GameState {
  /// NxN grid of tile states
  final List<List<TileState>> board;
  
  /// Grid size (NxN)
  final int gridSize;
  
  /// Current positions of both players
  final Position player1Position;
  final Position player2Position;
  
  /// Whose turn is it
  final Player currentPlayer;
  
  /// Game result
  final GameResult result;
  
  /// Position of tile currently being animated (falling)
  final Position? fallingTilePosition;
  
  /// Game settings (colors, etc.)
  final GameSettings settings;
  
  /// Move counter (total moves made in the game)
  final int moveCount;

  const GameState({
    required this.board,
    required this.gridSize,
    required this.player1Position,
    required this.player2Position,
    required this.currentPlayer,
    required this.settings,
    this.result = GameResult.ongoing,
    this.fallingTilePosition,
    this.moveCount = 0,
  });

  /// Create initial game state with given settings
  factory GameState.initial(GameSettings settings) {
    final size = settings.gridSize;
    
    // TEMPORARY TIE DEMO: Set to true to start with only 3 tiles for screenshotting
    const tieDemoMode = false; // <-- DISABLED - normal gameplay restored
    
    if (tieDemoMode && size == 8) {
      // Tie demo: Only 3 tiles remain - P1 at (0,0), empty at (1,2), P2 at (3,3)
      // One move by P1 to (1,2) triggers tie!
      final board = List.generate(
        size,
        (row) => List.generate(size, (col) {
          // Only these 3 tiles are active: (0,0), (1,2), (3,3)
          if ((row == 0 && col == 0) || 
              (row == 1 && col == 2) || 
              (row == 3 && col == 3)) {
            return const TileState(); // Active
          }
          return const TileState(status: TileStatus.void_); // Void
        }),
      );
      
      return GameState(
        board: board,
        gridSize: size,
        player1Position: const Position(0, 0),
        player2Position: const Position(3, 3),
        currentPlayer: Player.player1,
        settings: settings,
        moveCount: 0,
      );
    }
    
    // Knight's Tour mode: Start with all tiles active, but player hasn't chosen position yet
    // We use a special marker position (-1, -1) to indicate "not yet placed"
    if (settings.gameMode == GameMode.knightsTour) {
      final board = List.generate(
        size,
        (_) => List.generate(size, (_) => const TileState()),
      );
      
      return GameState(
        board: board,
        gridSize: size,
        player1Position: const Position(-1, -1), // Not yet placed
        player2Position: const Position(-1, -1), // No player 2 in this mode
        currentPlayer: Player.player1,
        settings: settings,
        moveCount: 0,
      );
    }
    
    // Normal mode: Initialize NxN board with all active tiles
    final board = List.generate(
      size,
      (_) => List.generate(size, (_) => const TileState()),
    );

    return GameState(
      board: board,
      gridSize: size,
      player1Position: const Position(0, 0), // Top-left
      player2Position: Position(size - 1, size - 1), // Bottom-right
      currentPlayer: Player.player1,
      settings: settings,
      moveCount: 0,
    );
  }

  /// Check if this is player 2's first move (capture not allowed)
  bool get isPlayer2FirstMove => 
      currentPlayer == Player.player2 && moveCount == 1;

  /// Get position of a specific player
  Position getPlayerPosition(Player player) {
    return player == Player.player1 ? player1Position : player2Position;
  }

  /// Get all valid moves for the current player
  List<Position> getValidMoves() {
    final currentPos = getPlayerPosition(currentPlayer);
    
    // If in Knight's Tour mode and position hasn't been set yet, all tiles are valid
    if (settings.gameMode == GameMode.knightsTour && currentPos.row == -1) {
      List<Position> allPositions = [];
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          if (board[row][col].isPlayable) {
            allPositions.add(Position(row, col));
          }
        }
      }
      return allPositions;
    }
    
    final opponentPos = getPlayerPosition(currentPlayer.opponent);
    final potentialMoves = currentPos.getKnightMoves(gridSize);
    
    return potentialMoves.where((pos) {
      // Must be on board
      if (!pos.isOnBoard(gridSize)) return false;
      // Must be a playable tile (not void or falling)
      if (!board[pos.row][pos.col].isPlayable) return false;
      // On player 2's first move, cannot capture (fair play rule)
      if (isPlayer2FirstMove && pos == opponentPos) return false;
      return true;
    }).toList();
  }

  /// Check if a position is a valid move for current player
  bool isValidMove(Position target) {
    return getValidMoves().contains(target);
  }

  /// Count the number of active (playable) tiles on the board
  int countActiveTiles() {
    int count = 0;
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (board[row][col].isPlayable) {
          count++;
        }
      }
    }
    return count;
  }

  /// Get tile state at position
  TileState getTileAt(Position pos) => board[pos.row][pos.col];

  /// Create a copy with modified fields
  GameState copyWith({
    List<List<TileState>>? board,
    int? gridSize,
    Position? player1Position,
    Position? player2Position,
    Player? currentPlayer,
    GameResult? result,
    Position? fallingTilePosition,
    GameSettings? settings,
    int? moveCount,
    bool clearFallingTile = false,
  }) {
    return GameState(
      board: board ?? this.board,
      gridSize: gridSize ?? this.gridSize,
      player1Position: player1Position ?? this.player1Position,
      player2Position: player2Position ?? this.player2Position,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      result: result ?? this.result,
      settings: settings ?? this.settings,
      moveCount: moveCount ?? this.moveCount,
      fallingTilePosition: clearFallingTile ? null : (fallingTilePosition ?? this.fallingTilePosition),
    );
  }

  /// Deep copy the board
  List<List<TileState>> copyBoard() {
    return board.map((row) => row.toList()).toList();
  }
}

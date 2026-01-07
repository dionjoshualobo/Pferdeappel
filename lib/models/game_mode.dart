/// Represents the different game modes available
enum GameMode {
  /// Traditional two-player mode
  vsPlayer,
  
  /// Player vs Computer mode
  vsComputer,
  
  /// Single-player Knight's Tour puzzle mode
  knightsTour,
}

extension GameModeExtension on GameMode {
  /// Display name for the game mode
  String get displayName {
    switch (this) {
      case GameMode.vsPlayer:
        return 'Player vs Player';
      case GameMode.vsComputer:
        return 'Player vs Computer';
      case GameMode.knightsTour:
        return "Knight's Tour";
    }
  }
  
  /// Check if this is a single-player mode
  bool get isSinglePlayer => this == GameMode.knightsTour;
  
  /// Check if this is a two-player mode
  bool get isTwoPlayer => this == GameMode.vsPlayer || this == GameMode.vsComputer;
}

import 'package:flutter/material.dart';
import 'game_settings.dart';

/// Represents a player in the game
enum Player {
  player1,
  player2;

  /// Get display name based on whether this player is a computer
  String getDisplayName(GameSettings settings) {
    final isComputer = this == player1 
        ? settings.isPlayer1Computer 
        : settings.isPlayer2Computer;
    return isComputer ? 'Computer' : 'Player';
  }

  /// Legacy display name for backwards compatibility
  String get displayName => this == player1 ? 'Player 1' : 'Player 2';

  /// Check if this player is a computer
  bool isComputer(GameSettings settings) {
    return this == player1 
        ? settings.isPlayer1Computer 
        : settings.isPlayer2Computer;
  }

  /// Get the opponent
  Player get opponent => this == player1 ? player2 : player1;

  /// Get color from settings
  Color getColor(GameSettings settings) {
    return this == player1 ? settings.player1Color : settings.player2Color;
  }

  /// Get accent color from settings
  Color getAccentColor(GameSettings settings) {
    return GameSettings.getAccentColor(getColor(settings));
  }
}

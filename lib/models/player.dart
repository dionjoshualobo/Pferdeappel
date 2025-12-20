import 'package:flutter/material.dart';
import 'game_settings.dart';

/// Represents a player in the game
enum Player {
  player1,
  player2;

  String get displayName => this == player1 ? 'Player 1' : 'Player 2';

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

import 'package:flutter/material.dart';

/// Game settings that can be configured from the home screen
class GameSettings {
  final int gridSize;
  final Color player1Color;
  final Color player2Color;

  const GameSettings({
    this.gridSize = 8,
    this.player1Color = const Color(0xFFFFD700), // Gold
    this.player2Color = const Color(0xFF9B59B6), // Purple
  });

  /// Available colors for players to choose from
  static const List<Color> availableColors = [
    Color(0xFFFFD700), // Gold/Yellow
    Color(0xFFE74C3C), // Red
    Color(0xFF2ECC71), // Bright Green
    Color(0xFF040877), // Dark Blue
    Color(0xFF4ECDC4), // Teal
    Color(0xFF9B59B6), // Purple
    Color(0xFF1D6B4C), // Dark Green
    Color(0xFF2C3E50), // Dark Gray/Black
    Color(0xFFFF9F43), // Orange
    Color(0xFFE91E63), // Magenta/Pink
    Color(0xFFE0E0E0), // Silver/White
    Color(0xFF8B4513), // Brown
  ];

  /// Get accent color (slightly darker) for a given color
  static Color getAccentColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  GameSettings copyWith({
    int? gridSize,
    Color? player1Color,
    Color? player2Color,
  }) {
    return GameSettings(
      gridSize: gridSize ?? this.gridSize,
      player1Color: player1Color ?? this.player1Color,
      player2Color: player2Color ?? this.player2Color,
    );
  }
}

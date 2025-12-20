/// Represents the state of a single tile on the board
enum TileStatus {
  /// Tile is active and can be landed on
  active,
  /// Tile is currently animating its fall
  falling,
  /// Tile has fallen into the abyss (void)
  void_,
}

class TileState {
  final TileStatus status;

  const TileState({this.status = TileStatus.active});

  bool get isPlayable => status == TileStatus.active;
  bool get isFalling => status == TileStatus.falling;
  bool get isVoid => status == TileStatus.void_;

  TileState copyWith({TileStatus? status}) {
    return TileState(status: status ?? this.status);
  }
}

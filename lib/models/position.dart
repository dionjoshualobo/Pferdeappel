/// Represents a position on the grid
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// All possible knight move offsets (L-shape)
  static const List<List<int>> knightOffsets = [
    [-2, -1], [-2, 1],
    [-1, -2], [-1, 2],
    [1, -2], [1, 2],
    [2, -1], [2, 1],
  ];

  /// Get all valid knight moves from this position for a given grid size
  List<Position> getKnightMoves(int gridSize) {
    return knightOffsets
        .map((offset) => Position(row + offset[0], col + offset[1]))
        .where((pos) => pos.isOnBoard(gridSize))
        .toList();
  }

  /// Check if position is within the grid
  bool isOnBoard(int gridSize) => 
      row >= 0 && row < gridSize && col >= 0 && col < gridSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}

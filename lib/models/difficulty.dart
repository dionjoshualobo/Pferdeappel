/// Difficulty levels for the computer opponent
enum Difficulty {
  easy,
  medium,
  hard,
  impossible;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.impossible:
        return 'Impossible';
    }
  }
}

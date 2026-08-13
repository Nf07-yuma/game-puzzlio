import 'dart:math';

/// A 4x4 sliding puzzle (15-puzzle). Tiles are numbered 1..15, `0` is the
/// blank space. [tiles] is stored row-major.
class SlidingPuzzleBoard {
  static const int size = 4;

  const SlidingPuzzleBoard(this.tiles);

  final List<int> tiles;

  static List<int> get _solvedTiles => [
        for (var i = 1; i < size * size; i++) i,
        0,
      ];

  factory SlidingPuzzleBoard.solved() =>
      SlidingPuzzleBoard(List.unmodifiable(_solvedTiles));

  bool get isSolved {
    final solved = _solvedTiles;
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != solved[i]) return false;
    }
    return true;
  }

  int get blankIndex => tiles.indexOf(0);

  /// Returns the list of tile indices adjacent to the blank space, i.e. the
  /// tiles that can legally move.
  List<int> get movableIndices {
    final blank = blankIndex;
    final row = blank ~/ size;
    final col = blank % size;
    final result = <int>[];
    if (row > 0) result.add(blank - size);
    if (row < size - 1) result.add(blank + size);
    if (col > 0) result.add(blank - 1);
    if (col < size - 1) result.add(blank + 1);
    return result;
  }

  /// Slides the tile at [index] into the blank space, if adjacent.
  /// Returns the same board if the move is illegal.
  SlidingPuzzleBoard tap(int index) {
    if (!movableIndices.contains(index)) return this;
    final next = List<int>.from(tiles);
    final blank = blankIndex;
    next[blank] = next[index];
    next[index] = 0;
    return SlidingPuzzleBoard(next);
  }

  /// Produces a shuffled, always-solvable board by making [moveCount]
  /// random legal moves starting from the solved state.
  factory SlidingPuzzleBoard.shuffled(Random random, {int moveCount = 200}) {
    var board = SlidingPuzzleBoard.solved();
    int? lastBlank;
    for (var i = 0; i < moveCount; i++) {
      final options =
          board.movableIndices.where((index) => index != lastBlank).toList();
      final candidates = options.isEmpty ? board.movableIndices : options;
      final choice = candidates[random.nextInt(candidates.length)];
      lastBlank = board.blankIndex;
      board = board.tap(choice);
    }
    return board;
  }
}

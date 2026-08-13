import 'dart:math';

enum SwipeDirection { up, down, left, right }

/// Immutable 4x4 board for the 2048 game, `0` represents an empty cell.
class Board2048 {
  static const int size = 4;

  const Board2048(this.tiles);

  /// Row-major list of length [size] * [size].
  final List<int> tiles;

  int at(int row, int col) => tiles[row * size + col];

  factory Board2048.empty() => Board2048(List.filled(size * size, 0));

  List<List<int>> get grid => List.generate(
        size,
        (row) => List.generate(size, (col) => at(row, col)),
      );

  bool get isFull => !tiles.contains(0);

  List<int> get emptyIndices => [
        for (var i = 0; i < tiles.length; i++)
          if (tiles[i] == 0) i,
      ];

  bool get hasWon => tiles.any((t) => t >= 2048);

  Board2048 withRandomTile(Random random) {
    final empties = emptyIndices;
    if (empties.isEmpty) return this;
    final index = empties[random.nextInt(empties.length)];
    final value = random.nextDouble() < 0.9 ? 2 : 4;
    final next = List<int>.from(tiles);
    next[index] = value;
    return Board2048(next);
  }

  bool get canMove {
    if (!isFull) return true;
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final value = at(row, col);
        if (col + 1 < size && at(row, col + 1) == value) return true;
        if (row + 1 < size && at(row + 1, col) == value) return true;
      }
    }
    return false;
  }

  /// Slides and merges tiles in [direction]. Returns the resulting board and
  /// the score gained. If nothing moved, the returned board is `identical`
  /// in content to this one and [Move2048Result.moved] is false.
  Move2048Result move(SwipeDirection direction) {
    final lines = _extractLines(direction);
    var scoreGained = 0;
    var moved = false;
    final resultLines = <List<int>>[];

    for (final line in lines) {
      final merged = _mergeLine(line);
      resultLines.add(merged.line);
      scoreGained += merged.scoreGained;
      if (!moved && !_listEquals(line, merged.line)) moved = true;
    }

    final newBoard = _rebuildFromLines(resultLines, direction);
    return Move2048Result(
      board: moved ? newBoard : this,
      scoreGained: scoreGained,
      moved: moved,
    );
  }

  List<List<int>> _extractLines(SwipeDirection direction) {
    final g = grid;
    switch (direction) {
      case SwipeDirection.left:
        return List.generate(size, (row) => g[row]);
      case SwipeDirection.right:
        return List.generate(size, (row) => g[row].reversed.toList());
      case SwipeDirection.up:
        return List.generate(
          size,
          (col) => List.generate(size, (row) => g[row][col]),
        );
      case SwipeDirection.down:
        return List.generate(
          size,
          (col) => List.generate(size, (row) => g[size - 1 - row][col]),
        );
    }
  }

  Board2048 _rebuildFromLines(
    List<List<int>> lines,
    SwipeDirection direction,
  ) {
    final g = List.generate(size, (_) => List.filled(size, 0));
    switch (direction) {
      case SwipeDirection.left:
        for (var row = 0; row < size; row++) {
          g[row] = lines[row];
        }
        break;
      case SwipeDirection.right:
        for (var row = 0; row < size; row++) {
          g[row] = lines[row].reversed.toList();
        }
        break;
      case SwipeDirection.up:
        for (var col = 0; col < size; col++) {
          for (var row = 0; row < size; row++) {
            g[row][col] = lines[col][row];
          }
        }
        break;
      case SwipeDirection.down:
        for (var col = 0; col < size; col++) {
          for (var row = 0; row < size; row++) {
            g[size - 1 - row][col] = lines[col][row];
          }
        }
        break;
    }
    return Board2048([for (final row in g) ...row]);
  }

  ({List<int> line, int scoreGained}) _mergeLine(List<int> line) {
    final nonZero = line.where((v) => v != 0).toList();
    final result = <int>[];
    var scoreGained = 0;
    var i = 0;
    while (i < nonZero.length) {
      if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
        final mergedValue = nonZero[i] * 2;
        result.add(mergedValue);
        scoreGained += mergedValue;
        i += 2;
      } else {
        result.add(nonZero[i]);
        i += 1;
      }
    }
    while (result.length < size) {
      result.add(0);
    }
    return (line: result, scoreGained: scoreGained);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class Move2048Result {
  const Move2048Result({
    required this.board,
    required this.scoreGained,
    required this.moved,
  });

  final Board2048 board;
  final int scoreGained;
  final bool moved;
}

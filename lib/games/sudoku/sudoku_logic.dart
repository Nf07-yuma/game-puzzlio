import 'dart:math';

enum SudokuDifficulty { easy, medium, hard }

extension SudokuDifficultyX on SudokuDifficulty {
  String get label => switch (this) {
        SudokuDifficulty.easy => 'かんたん',
        SudokuDifficulty.medium => 'ふつう',
        SudokuDifficulty.hard => 'むずかしい',
      };

  /// Number of pre-filled cells left in the puzzle.
  int get clueCount => switch (this) {
        SudokuDifficulty.easy => 42,
        SudokuDifficulty.medium => 34,
        SudokuDifficulty.hard => 27,
      };
}

/// A generated Sudoku puzzle: a full valid [solution] and a [puzzle] with
/// some cells blanked out (`0`), guaranteed to have a unique solution.
/// All lists are length 81, row-major (index = row * 9 + col).
class SudokuPuzzle {
  const SudokuPuzzle({required this.solution, required this.puzzle});

  final List<int> solution;
  final List<int> puzzle;

  bool isGiven(int index) => puzzle[index] != 0;

  factory SudokuPuzzle.generate(Random random, SudokuDifficulty difficulty) {
    final solution = _generateSolvedGrid(random);
    final puzzle = List<int>.from(solution);

    final indices = List<int>.generate(81, (i) => i)..shuffle(random);
    var remaining = 81;
    final target = difficulty.clueCount;

    for (final index in indices) {
      if (remaining <= target) break;
      final backup = puzzle[index];
      puzzle[index] = 0;
      if (_countSolutions(puzzle, limit: 2) == 1) {
        remaining--;
      } else {
        puzzle[index] = backup;
      }
    }

    return SudokuPuzzle(solution: solution, puzzle: puzzle);
  }

  static List<int> _generateSolvedGrid(Random random) {
    final grid = List<int>.filled(81, 0);
    _fillGrid(grid, 0, random);
    return grid;
  }

  static bool _fillGrid(List<int> grid, int index, Random random) {
    if (index == 81) return true;
    if (grid[index] != 0) return _fillGrid(grid, index + 1, random);

    final row = index ~/ 9;
    final col = index % 9;
    final candidates = List<int>.generate(9, (i) => i + 1)..shuffle(random);
    for (final value in candidates) {
      if (_isSafe(grid, row, col, value)) {
        grid[index] = value;
        if (_fillGrid(grid, index + 1, random)) return true;
        grid[index] = 0;
      }
    }
    return false;
  }

  /// Counts solutions of [grid] up to [limit] (for performance, we only
  /// need to distinguish 0 / 1 / "more than 1").
  static int _countSolutions(List<int> grid, {required int limit}) {
    final working = List<int>.from(grid);
    var count = 0;

    bool search(int index) {
      if (index == 81) {
        count++;
        return count >= limit;
      }
      if (working[index] != 0) return search(index + 1);

      final row = index ~/ 9;
      final col = index % 9;
      for (var value = 1; value <= 9; value++) {
        if (_isSafe(working, row, col, value)) {
          working[index] = value;
          if (search(index + 1)) return true;
          working[index] = 0;
        }
      }
      return false;
    }

    search(0);
    return count;
  }

  static bool _isSafe(List<int> grid, int row, int col, int value) {
    for (var i = 0; i < 9; i++) {
      if (grid[row * 9 + i] == value) return false;
      if (grid[i * 9 + col] == value) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        if (grid[(boxRow + r) * 9 + (boxCol + c)] == value) return false;
      }
    }
    return true;
  }

  /// Returns the set of cell indices in [grid] that conflict with another
  /// cell in the same row, column, or 3x3 box.
  static Set<int> findConflicts(List<int> grid) {
    final conflicts = <int>{};
    for (var row = 0; row < 9; row++) {
      _collectConflicts(grid, conflicts, List.generate(9, (c) => row * 9 + c));
    }
    for (var col = 0; col < 9; col++) {
      _collectConflicts(grid, conflicts, List.generate(9, (r) => r * 9 + col));
    }
    for (var boxRow = 0; boxRow < 3; boxRow++) {
      for (var boxCol = 0; boxCol < 3; boxCol++) {
        final cells = [
          for (var r = 0; r < 3; r++)
            for (var c = 0; c < 3; c++) (boxRow * 3 + r) * 9 + (boxCol * 3 + c),
        ];
        _collectConflicts(grid, conflicts, cells);
      }
    }
    return conflicts;
  }

  static void _collectConflicts(
    List<int> grid,
    Set<int> conflicts,
    List<int> cellIndices,
  ) {
    final seen = <int, int>{};
    for (final index in cellIndices) {
      final value = grid[index];
      if (value == 0) continue;
      if (seen.containsKey(value)) {
        conflicts.add(index);
        conflicts.add(seen[value]!);
      } else {
        seen[value] = index;
      }
    }
  }
}

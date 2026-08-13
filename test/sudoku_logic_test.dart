import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/games/sudoku/sudoku_logic.dart';

void main() {
  group('SudokuPuzzle', () {
    test('generated solution has no rule conflicts', () {
      final puzzle = SudokuPuzzle.generate(Random(1), SudokuDifficulty.easy);
      expect(SudokuPuzzle.findConflicts(puzzle.solution), isEmpty);
    });

    test('generated puzzle leaves the requested number of clues', () {
      final puzzle = SudokuPuzzle.generate(
        Random(1),
        SudokuDifficulty.hard,
      );
      final clueCount = puzzle.puzzle.where((v) => v != 0).length;
      expect(clueCount, SudokuDifficulty.hard.clueCount);
    });

    test('puzzle clues match the solution', () {
      final puzzle = SudokuPuzzle.generate(
        Random(2),
        SudokuDifficulty.medium,
      );
      for (var i = 0; i < 81; i++) {
        if (puzzle.puzzle[i] != 0) {
          expect(puzzle.puzzle[i], puzzle.solution[i]);
        }
      }
    });

    test('findConflicts detects duplicate values in a row', () {
      final grid = List<int>.filled(81, 0);
      grid[0] = 5;
      grid[1] = 5;
      final conflicts = SudokuPuzzle.findConflicts(grid);
      expect(conflicts, containsAll([0, 1]));
    });
  });
}

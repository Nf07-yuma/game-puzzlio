import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/games/territory/territory_logic.dart';

void main() {
  group('TerritoryPuzzle', () {
    test('sizeForLevel grows every 3 levels and stays within bounds', () {
      expect(TerritoryPuzzle.sizeForLevel(1), 5);
      expect(TerritoryPuzzle.sizeForLevel(3), 5);
      expect(TerritoryPuzzle.sizeForLevel(4), 6);
      expect(TerritoryPuzzle.sizeForLevel(1000), 10);
    });

    for (final size in [5, 6, 7, 8]) {
      test('generated size-$size puzzle has a unique, valid solution', () {
        final puzzle = TerritoryPuzzle.generate(Random(size), size);

        expect(puzzle.regions.length, size * size);
        expect(puzzle.solutionColumns.length, size);
        expect(puzzle.solutionColumns.toSet().length, size,
            reason: 'solution must use every column exactly once');

        // Every region id 0..size-1 must be used and contain the matching
        // solution cell.
        for (var region = 0; region < size; region++) {
          expect(puzzle.regions, contains(region));
          final index = region * size + puzzle.solutionColumns[region];
          expect(puzzle.regions[index], region);
        }

        // The reference solution itself must satisfy the rules.
        final board = List<TerritoryCellState>.filled(
            size * size, TerritoryCellState.empty);
        for (var row = 0; row < size; row++) {
          board[row * size + puzzle.solutionColumns[row]] =
              TerritoryCellState.flag;
        }
        final validation =
            TerritoryPuzzle.validate(size, puzzle.regions, board);
        expect(validation.solved, isTrue);
        expect(validation.conflicts, isEmpty);

        expect(
            TerritoryPuzzle.countSolutions(size, puzzle.regions, limit: 2), 1);
      });
    }

    test('validate flags flags sharing a row', () {
      const size = 5;
      final regions = List<int>.generate(size * size, (i) => i % size);
      final board = List<TerritoryCellState>.filled(
          size * size, TerritoryCellState.empty);
      board[0] = TerritoryCellState.flag; // row 0, col 0
      board[2] = TerritoryCellState.flag; // row 0, col 2
      final validation = TerritoryPuzzle.validate(size, regions, board);
      expect(validation.solved, isFalse);
      expect(validation.conflicts, containsAll([0, 2]));
    });

    test('validate flags adjacent (touching) flags', () {
      const size = 5;
      final regions = List<int>.generate(size * size, (i) => i % size);
      final board = List<TerritoryCellState>.filled(
          size * size, TerritoryCellState.empty);
      board[0] = TerritoryCellState.flag; // row 0, col 0
      board[size + 1] = TerritoryCellState.flag; // row 1, col 1 (diagonal)
      final validation = TerritoryPuzzle.validate(size, regions, board);
      expect(validation.solved, isFalse);
      expect(validation.conflicts, containsAll([0, size + 1]));
    });

    test('validate flags flags sharing a color region', () {
      const size = 5;
      final regions = List<int>.filled(size * size, 0);
      final board = List<TerritoryCellState>.filled(
          size * size, TerritoryCellState.empty);
      board[0] = TerritoryCellState.flag; // row 0, col 0
      board[2 * size + 4] =
          TerritoryCellState.flag; // row 2, col 4, same region
      final validation = TerritoryPuzzle.validate(size, regions, board);
      expect(validation.solved, isFalse);
      expect(validation.conflicts, containsAll([0, 2 * size + 4]));
    });

    test('validate reports solved only when every rule is satisfied', () {
      final puzzle = TerritoryPuzzle.generate(Random(7), 6);
      final board = List<TerritoryCellState>.filled(
          puzzle.size * puzzle.size, TerritoryCellState.empty);
      expect(
        TerritoryPuzzle.validate(puzzle.size, puzzle.regions, board).solved,
        isFalse,
      );
      for (var row = 0; row < puzzle.size; row++) {
        board[row * puzzle.size + puzzle.solutionColumns[row]] =
            TerritoryCellState.flag;
      }
      expect(
        TerritoryPuzzle.validate(puzzle.size, puzzle.regions, board).solved,
        isTrue,
      );
    });
  });
}

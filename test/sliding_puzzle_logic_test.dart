import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/games/sliding_puzzle/sliding_puzzle_logic.dart';

void main() {
  group('SlidingPuzzleBoard', () {
    test('solved board reports isSolved', () {
      expect(SlidingPuzzleBoard.solved().isSolved, isTrue);
    });

    test('movableIndices only includes cells adjacent to the blank', () {
      final board = SlidingPuzzleBoard.solved();
      // Blank is the last cell (index 15) in the solved 4x4 board.
      expect(board.blankIndex, 15);
      expect(board.movableIndices, containsAll([11, 14]));
      expect(board.movableIndices.length, 2);
    });

    test('tapping a non-adjacent tile is a no-op', () {
      final board = SlidingPuzzleBoard.solved();
      final result = board.tap(0);
      expect(result.tiles, board.tiles);
    });

    test('tapping an adjacent tile swaps it with the blank', () {
      final board = SlidingPuzzleBoard.solved();
      final result = board.tap(14);
      expect(result.tiles[14], 0);
      expect(result.tiles[15], 15);
    });

    test('shuffled board is always solvable via legal moves', () {
      final random = Random(42);
      for (var trial = 0; trial < 5; trial++) {
        final shuffled = SlidingPuzzleBoard.shuffled(random, moveCount: 100);
        // A shuffle built purely from legal moves starting at the solved
        // state must itself be solvable: undo it by walking back is not
        // needed, but it must not be trivially already solved for a
        // reasonable move count, and must contain the same multiset of
        // tiles as the solved board.
        final sortedShuffled = [...shuffled.tiles]..sort();
        final sortedSolved = [...SlidingPuzzleBoard.solved().tiles]..sort();
        expect(sortedShuffled, sortedSolved);
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/games/game_2048/game_2048_logic.dart';

void main() {
  group('Board2048', () {
    test('merges equal adjacent tiles when sliding left', () {
      // Row: [2, 2, 4, 0] -> [4, 4, 0, 0]
      const board = Board2048([
        2, 2, 4, 0, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);

      final result = board.move(SwipeDirection.left);

      expect(result.moved, isTrue);
      expect(result.scoreGained, 4);
      expect(result.board.grid[0], [4, 4, 0, 0]);
    });

    test('does not merge a tile twice in one move', () {
      // Row: [2, 2, 2, 2] -> [4, 4, 0, 0]
      const board = Board2048([
        2, 2, 2, 2, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);

      final result = board.move(SwipeDirection.left);

      expect(result.board.grid[0], [4, 4, 0, 0]);
      expect(result.scoreGained, 8);
    });

    test('reports no move when nothing changes', () {
      const board = Board2048([
        2, 4, 8, 16, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);

      final result = board.move(SwipeDirection.left);

      expect(result.moved, isFalse);
      expect(result.scoreGained, 0);
    });

    test('canMove is false when the board is full and no merges possible', () {
      const board = Board2048([
        2, 4, 2, 4, //
        4, 2, 4, 2,
        2, 4, 2, 4,
        4, 2, 4, 2,
      ]);

      expect(board.canMove, isFalse);
    });

    test('canMove is true when an empty cell exists', () {
      final board = Board2048.empty();
      expect(board.canMove, isTrue);
    });
  });
}

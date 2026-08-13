import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlio/games/game_2048/game_2048_logic.dart';
import 'package:puzzlio/games/game_2048/game_2048_tile_animation.dart';

/// Assigns each non-zero cell a unique id in row-major order, mirroring how
/// [_Game2048ScreenState._tilesFromBoard] seeds tile identity from a board.
List<AnimatedTile> _tilesFromFlat(List<int> flat, {int size = Board2048.size}) {
  final tiles = <AnimatedTile>[];
  for (var i = 0; i < flat.length; i++) {
    if (flat[i] == 0) continue;
    tiles.add(
      AnimatedTile(id: i, value: flat[i], row: i ~/ size, col: i % size),
    );
  }
  return tiles;
}

List<int> _toFlat(List<AnimatedTile> tiles, {int size = Board2048.size}) {
  final flat = List<int>.filled(size * size, 0);
  for (final tile in tiles) {
    flat[tile.row * size + tile.col] = tile.value;
  }
  return flat;
}

void main() {
  group('slideAnimatedTiles', () {
    void expectMatchesBoardMove(List<int> flat, SwipeDirection direction) {
      final board = Board2048(flat);
      final expected = board.move(direction).board.tiles;

      final slid = slideAnimatedTiles(_tilesFromFlat(flat), direction);
      final actual = _toFlat(slid);

      expect(actual, expected);
    }

    test('matches Board2048.move when sliding left with a merge', () {
      expectMatchesBoardMove([
        2, 2, 4, 0, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ], SwipeDirection.left);
    });

    test('matches Board2048.move when sliding right with a merge', () {
      expectMatchesBoardMove([
        0, 2, 2, 4, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ], SwipeDirection.right);
    });

    test('matches Board2048.move when sliding up a full column', () {
      expectMatchesBoardMove([
        0, 0, 0, 0, //
        2, 0, 0, 0,
        2, 0, 0, 0,
        4, 0, 0, 0,
      ], SwipeDirection.up);
    });

    test('matches Board2048.move when sliding down with no merges', () {
      expectMatchesBoardMove([
        2, 0, 0, 0, //
        4, 0, 0, 0,
        8, 0, 0, 0,
        0, 0, 0, 0,
      ], SwipeDirection.down);
    });

    test('does not merge a tile twice in one move', () {
      expectMatchesBoardMove([
        2, 2, 2, 2, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ], SwipeDirection.left);
    });

    test('merged tile keeps the leading tile\'s id and marks justMerged', () {
      final tiles = [
        const AnimatedTile(id: 11, value: 2, row: 0, col: 0),
        const AnimatedTile(id: 22, value: 2, row: 0, col: 1),
      ];

      final result = slideAnimatedTiles(tiles, SwipeDirection.left);

      expect(result, hasLength(1));
      expect(result.single.id, 11);
      expect(result.single.value, 4);
      expect(result.single.justMerged, isTrue);
      expect(result.single.row, 0);
      expect(result.single.col, 0);
    });

    test('a tile that does not move keeps its id and position', () {
      final tiles = [const AnimatedTile(id: 5, value: 2, row: 0, col: 0)];

      final result = slideAnimatedTiles(tiles, SwipeDirection.left);

      expect(result.single.id, 5);
      expect(result.single.row, 0);
      expect(result.single.col, 0);
      expect(result.single.justMerged, isFalse);
    });
  });
}

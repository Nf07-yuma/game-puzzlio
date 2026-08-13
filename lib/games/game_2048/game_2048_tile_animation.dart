import 'game_2048_logic.dart';

/// A single visual tile tracked by a stable [id] across moves, so the UI can
/// animate it sliding to its new position instead of values teleporting
/// between cells. [Board2048] only tracks values per cell, so this is kept
/// as a separate, UI-side projection rather than changing that tested API.
class AnimatedTile {
  const AnimatedTile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.justMerged = false,
  });

  final int id;
  final int value;
  final int row;
  final int col;

  /// True for the tile spawned after a move (plays a grow-in animation).
  final bool isNew;

  /// True for a tile two equal tiles just merged into (plays a pop animation).
  final bool justMerged;
}

/// Slides [tiles] one step in [direction], merging equal adjacent tiles the
/// same way [Board2048.move] does: within each row/column, tiles compact
/// towards [direction] and equal neighbours merge pairwise without a tile
/// merging twice in one move. Each surviving tile keeps its [AnimatedTile.id]
/// so its widget can animate from its old position to its new one.
List<AnimatedTile> slideAnimatedTiles(
  List<AnimatedTile> tiles,
  SwipeDirection direction, {
  int size = Board2048.size,
}) {
  final isHorizontal =
      direction == SwipeDirection.left || direction == SwipeDirection.right;
  final ascending =
      direction == SwipeDirection.left || direction == SwipeDirection.up;

  final groups = <int, List<AnimatedTile>>{};
  for (final tile in tiles) {
    final groupKey = isHorizontal ? tile.row : tile.col;
    groups.putIfAbsent(groupKey, () => []).add(tile);
  }

  final result = <AnimatedTile>[];
  for (final entry in groups.entries) {
    final line = List<AnimatedTile>.from(entry.value)
      ..sort((a, b) {
        final ai = isHorizontal ? a.col : a.row;
        final bi = isHorizontal ? b.col : b.row;
        return ascending ? ai.compareTo(bi) : bi.compareTo(ai);
      });

    var slot = 0;
    var i = 0;
    while (i < line.length) {
      final mergeNext =
          i + 1 < line.length && line[i].value == line[i + 1].value;
      final placed = mergeNext
          ? AnimatedTile(
              id: line[i].id,
              value: line[i].value * 2,
              row: 0,
              col: 0,
              justMerged: true,
            )
          : AnimatedTile(
              id: line[i].id,
              value: line[i].value,
              row: 0,
              col: 0,
            );
      result.add(_placeAt(placed, entry.key, slot, direction, size));
      i += mergeNext ? 2 : 1;
      slot++;
    }
  }
  return result;
}

AnimatedTile _placeAt(
  AnimatedTile tile,
  int groupKey,
  int slot,
  SwipeDirection direction,
  int size,
) {
  switch (direction) {
    case SwipeDirection.left:
      return _withPosition(tile, row: groupKey, col: slot);
    case SwipeDirection.right:
      return _withPosition(tile, row: groupKey, col: size - 1 - slot);
    case SwipeDirection.up:
      return _withPosition(tile, row: slot, col: groupKey);
    case SwipeDirection.down:
      return _withPosition(tile, row: size - 1 - slot, col: groupKey);
  }
}

AnimatedTile _withPosition(
  AnimatedTile tile, {
  required int row,
  required int col,
}) {
  return AnimatedTile(
    id: tile.id,
    value: tile.value,
    row: row,
    col: col,
    isNew: tile.isNew,
    justMerged: tile.justMerged,
  );
}

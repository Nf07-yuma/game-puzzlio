import 'dart:math';

/// State of a single board cell as the player fills it in.
enum CatCellState {
  /// Untouched.
  empty,

  /// Marked with an X to note "no cat here" (does not affect win checks).
  marked,

  /// A cat has been placed here.
  cat,
}

/// Result of checking a board against the puzzle rules.
class CatQueensValidation {
  const CatQueensValidation({required this.conflicts, required this.solved});

  /// Indices of cats that break a rule (same row/column/region as another
  /// cat, or sit next to another cat).
  final Set<int> conflicts;

  /// True once exactly one cat sits in every row/column/region with no
  /// conflicts.
  final bool solved;
}

/// A "one cat per row, column and color region, no two cats touching"
/// puzzle -- the classic "Queens" mechanic reskinned with cats.
///
/// [regions] is a row-major list of length `size * size` giving the color
/// region id (0..size-1) of each cell. [solutionColumns] gives one valid
/// solution: `solutionColumns[row]` is the column of the cat in that row.
class CatQueensPuzzle {
  const CatQueensPuzzle({
    required this.size,
    required this.regions,
    required this.solutionColumns,
  });

  final int size;
  final List<int> regions;
  final List<int> solutionColumns;

  int regionAt(int index) => regions[index];

  /// Smallest board size for which a valid puzzle can exist: below this,
  /// there aren't enough columns to keep every row's cat non-adjacent to
  /// the next while still using every column exactly once.
  static const int minSize = 4;

  /// Grows the board every few levels, capped so generation/solving stays
  /// fast and the board still fits comfortably on screen.
  static int sizeForLevel(int level) {
    final size = minSize + 1 + (level - 1) ~/ 3;
    return size.clamp(minSize, 10);
  }

  factory CatQueensPuzzle.generate(Random random, int size) {
    assert(size >= minSize);
    CatQueensPuzzle? best;
    for (var attempt = 0; attempt < 40; attempt++) {
      final solutionColumns = _generateSolution(random, size);
      final regions = _generateRegions(random, size, solutionColumns);
      // A freshly grown region layout is rarely uniquely solvable on its
      // own; nudge boundary cells between regions until the ambiguous
      // alternate solutions are eliminated (or we run out of budget).
      _repairForUniqueness(random, size, regions, solutionColumns);
      final puzzle = CatQueensPuzzle(
        size: size,
        regions: regions,
        solutionColumns: solutionColumns,
      );
      best = puzzle;
      if (countSolutions(size, regions, limit: 2) == 1) {
        return puzzle;
      }
    }
    // Couldn't find a uniquely-solvable layout in time; fall back to the
    // best (most recently repaired) candidate rather than looping forever.
    // It may admit more than one solution, but every rule still applies and
    // the board is still fully playable.
    return best!;
  }

  /// Tries to make [regions] uniquely solvable by relocating boundary cells
  /// (cells that aren't a region's original solution seed) away from
  /// whichever region an alternate solution is exploiting, one ambiguity at
  /// a time. Mutates [regions] in place; returns true once unique (or if it
  /// already was).
  static bool _repairForUniqueness(
    Random random,
    int size,
    List<int> regions,
    List<int> solutionColumns,
  ) {
    for (var iteration = 0; iteration < 60; iteration++) {
      final solutions = _firstSolutions(size, regions, limit: 2);
      if (solutions.length <= 1) return true;

      List<int>? alternate;
      for (final solution in solutions) {
        if (!_sameSolution(solution, solutionColumns)) {
          alternate = solution;
          break;
        }
      }
      if (alternate == null) return true;

      final rows = List<int>.generate(size, (i) => i)..shuffle(random);
      var moved = false;
      for (final row in rows) {
        final col = alternate[row];
        if (col == solutionColumns[row]) continue;

        final cell = row * size + col;
        final fromRegion = regions[cell];
        final seedIndex = fromRegion * size + solutionColumns[fromRegion];
        if (cell == seedIndex) continue; // never move a region's own seed
        if (!_regionStaysConnectedWithout(
            regions, size, fromRegion, cell, seedIndex)) {
          continue;
        }

        final neighborRegions = <int>{};
        for (final delta in const [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ]) {
          final nr = row + delta[0];
          final nc = col + delta[1];
          if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
          final region = regions[nr * size + nc];
          if (region != fromRegion) neighborRegions.add(region);
        }
        if (neighborRegions.isEmpty) continue;

        regions[cell] = neighborRegions.elementAt(
          random.nextInt(neighborRegions.length),
        );
        moved = true;
        break;
      }
      if (!moved) return false;
    }
    return _firstSolutions(size, regions, limit: 2).length == 1;
  }

  /// Whether [region] stays a single connected group (reachable from
  /// [seedIndex]) if [cellToRemove] were taken out of it.
  static bool _regionStaysConnectedWithout(
    List<int> regions,
    int size,
    int region,
    int cellToRemove,
    int seedIndex,
  ) {
    final remaining = <int>{
      for (var i = 0; i < regions.length; i++)
        if (regions[i] == region && i != cellToRemove) i,
    };
    if (remaining.isEmpty) return true;

    final visited = <int>{seedIndex};
    final stack = [seedIndex];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final row = current ~/ size;
      final col = current % size;
      for (final delta in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final nr = row + delta[0];
        final nc = col + delta[1];
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        final neighbor = nr * size + nc;
        if (remaining.contains(neighbor) && visited.add(neighbor)) {
          stack.add(neighbor);
        }
      }
    }
    return visited.length == remaining.length;
  }

  static bool _sameSolution(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Like [countSolutions] but returns the actual column assignments found
  /// (up to [limit]), used to diagnose *which* alternate solution to break.
  static List<List<int>> _firstSolutions(
    int size,
    List<int> regions, {
    required int limit,
  }) {
    final usedCols = List<bool>.filled(size, false);
    final usedRegions = List<bool>.filled(size, false);
    final current = List<int>.filled(size, -1);
    final results = <List<int>>[];

    void backtrack(int row, int prevCol) {
      if (results.length >= limit) return;
      if (row == size) {
        results.add(List<int>.from(current));
        return;
      }
      for (var col = 0; col < size; col++) {
        if (results.length >= limit) return;
        if (usedCols[col]) continue;
        if (prevCol != -1 && (col - prevCol).abs() <= 1) continue;
        final region = regions[row * size + col];
        if (usedRegions[region]) continue;
        usedCols[col] = true;
        usedRegions[region] = true;
        current[row] = col;
        backtrack(row + 1, col);
        usedCols[col] = false;
        usedRegions[region] = false;
        current[row] = -1;
      }
    }

    backtrack(0, -1);
    return results;
  }

  /// Picks one column per row (a permutation of `0..size-1`) such that no
  /// two consecutive rows use adjacent columns -- rows more than one apart
  /// can never touch, so that's the only case that needs checking.
  static List<int> _generateSolution(Random random, int size) {
    final assignment = List<int>.filled(size, -1);
    final used = List<bool>.filled(size, false);

    bool backtrack(int row) {
      if (row == size) return true;
      final candidates = List<int>.generate(size, (i) => i)..shuffle(random);
      for (final col in candidates) {
        if (used[col]) continue;
        if (row > 0 && (col - assignment[row - 1]).abs() <= 1) continue;
        assignment[row] = col;
        used[col] = true;
        if (backtrack(row + 1)) return true;
        used[col] = false;
        assignment[row] = -1;
      }
      return false;
    }

    final ok = backtrack(0);
    assert(ok, 'no valid cat placement exists for size $size');
    return assignment;
  }

  /// Grows one connected color region per row from its solution cell via
  /// randomized flood fill until every cell belongs to a region.
  static List<int> _generateRegions(
    Random random,
    int size,
    List<int> solutionColumns,
  ) {
    final regions = List<int>.filled(size * size, -1);
    final frontiers = <Set<int>>[];
    for (var region = 0; region < size; region++) {
      final index = region * size + solutionColumns[region];
      regions[index] = region;
      frontiers.add({index});
    }

    var remaining = size * size - size;
    final order = List<int>.generate(size, (i) => i);
    while (remaining > 0) {
      order.shuffle(random);
      var progressed = false;
      for (final region in order) {
        if (remaining == 0) break;
        final frontier = frontiers[region];
        if (frontier.isEmpty) continue;

        final candidates = <int>{};
        for (final cell in frontier) {
          final row = cell ~/ size;
          final col = cell % size;
          for (final delta in const [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1],
          ]) {
            final nr = row + delta[0];
            final nc = col + delta[1];
            if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
            final nIndex = nr * size + nc;
            if (regions[nIndex] == -1) candidates.add(nIndex);
          }
        }

        if (candidates.isEmpty) {
          frontier.clear();
          continue;
        }
        final chosen = candidates.elementAt(random.nextInt(candidates.length));
        regions[chosen] = region;
        frontier.add(chosen);
        remaining--;
        progressed = true;
      }
      if (!progressed) break;
    }

    // Safety net: a fully-enclosed cell whose region ran out of frontier
    // room shouldn't happen on a connected grid, but assign leftovers to a
    // neighboring region rather than leaving them unset.
    for (var i = 0; i < regions.length; i++) {
      if (regions[i] != -1) continue;
      final row = i ~/ size;
      final col = i % size;
      for (final delta in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final nr = row + delta[0];
        final nc = col + delta[1];
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        final nIndex = nr * size + nc;
        if (regions[nIndex] != -1) {
          regions[i] = regions[nIndex];
          break;
        }
      }
      regions[i] = regions[i] == -1 ? 0 : regions[i];
    }

    return regions;
  }

  /// Counts solutions of the region layout up to [limit] (only 0/1/"more
  /// than 1" matters, so search stops early once [limit] is reached).
  static int countSolutions(int size, List<int> regions, {int limit = 2}) {
    final usedCols = List<bool>.filled(size, false);
    final usedRegions = List<bool>.filled(size, false);
    var count = 0;

    void backtrack(int row, int prevCol) {
      if (count >= limit) return;
      if (row == size) {
        count++;
        return;
      }
      for (var col = 0; col < size; col++) {
        if (count >= limit) return;
        if (usedCols[col]) continue;
        if (prevCol != -1 && (col - prevCol).abs() <= 1) continue;
        final region = regions[row * size + col];
        if (usedRegions[region]) continue;
        usedCols[col] = true;
        usedRegions[region] = true;
        backtrack(row + 1, col);
        usedCols[col] = false;
        usedRegions[region] = false;
      }
    }

    backtrack(0, -1);
    return count;
  }

  /// Checks [board] (length `size * size`) against the row/column/region/
  /// adjacency rules.
  static CatQueensValidation validate(
    int size,
    List<int> regions,
    List<CatCellState> board,
  ) {
    final catIndices = [
      for (var i = 0; i < board.length; i++)
        if (board[i] == CatCellState.cat) i,
    ];
    final conflicts = <int>{};
    for (var i = 0; i < catIndices.length; i++) {
      final a = catIndices[i];
      final ar = a ~/ size;
      final ac = a % size;
      for (var j = i + 1; j < catIndices.length; j++) {
        final b = catIndices[j];
        final br = b ~/ size;
        final bc = b % size;
        final sameRow = ar == br;
        final sameCol = ac == bc;
        final sameRegion = regions[a] == regions[b];
        final adjacent = (ar - br).abs() <= 1 && (ac - bc).abs() <= 1;
        if (sameRow || sameCol || sameRegion || adjacent) {
          conflicts.add(a);
          conflicts.add(b);
        }
      }
    }
    final solved = catIndices.length == size && conflicts.isEmpty;
    return CatQueensValidation(conflicts: conflicts, solved: solved);
  }
}

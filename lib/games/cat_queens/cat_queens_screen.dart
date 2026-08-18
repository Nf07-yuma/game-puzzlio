import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_state_storage.dart';
import '../../services/score_service.dart';
import 'cat_queens_logic.dart';

enum _GameMenuAction { resetBoard, resetProgress }

/// Colors used for the puzzle's color regions, cycled by region id.
const List<Color> _regionColors = [
  Color(0xFFF6D860),
  Color(0xFF3FAE6A),
  Color(0xFF6FD98B),
  Color(0xFF52B7D9),
  Color(0xFFB5793C),
  Color(0xFFD9A441),
  Color(0xFFE87FAE),
  Color(0xFF8E7CD9),
  Color(0xFFE8955A),
  Color(0xFFC94F6D),
];

class CatQueensScreen extends StatefulWidget {
  const CatQueensScreen({super.key});

  @override
  State<CatQueensScreen> createState() => _CatQueensScreenState();
}

class _CatQueensScreenState extends State<CatQueensScreen> {
  static const String _gameId = 'cat_queens';
  static const String _savedStateId = 'cat_queens_current';

  /// How long after a cell is marked with an X a follow-up tap still turns
  /// it into a cat. A tap later than this (or on a cat) clears the cell
  /// instead.
  static const Duration _catWindow = Duration(seconds: 3);

  final Random _random = Random();

  int _level = 1;
  int _score = 0;
  int? _bestScore;
  late CatQueensPuzzle _puzzle;
  late List<CatCellState> _board;

  /// When each currently-marked cell became an X, keyed by cell index --
  /// used to decide whether the next tap on it should place a cat or clear
  /// it. Cells that aren't marked have no entry.
  final Map<int, DateTime> _markedAt = {};

  CatQueensValidation _validation = const CatQueensValidation(
    conflicts: {},
    solved: false,
  );

  @override
  void initState() {
    super.initState();
    _newPuzzleForLevel(_level);
    _restoreSavedGame();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final best = await ScoreService.instance.getBestScore(_gameId);
    if (mounted) setState(() => _bestScore = best);
  }

  Future<void> _restoreSavedGame() async {
    final saved = await GameStateStorage.instance.load(_savedStateId);
    if (!mounted || saved == null) return;
    final size = saved['size'] as int;
    final regions = (saved['regions'] as List).cast<int>();
    final solutionColumns = (saved['solutionColumns'] as List).cast<int>();
    final board = (saved['board'] as List)
        .cast<int>()
        .map((v) => CatCellState.values[v])
        .toList();
    setState(() {
      _level = saved['level'] as int;
      _score = saved['score'] as int;
      _puzzle = CatQueensPuzzle(
        size: size,
        regions: regions,
        solutionColumns: solutionColumns,
      );
      _board = board;
      _markedAt.clear();
      _validation = CatQueensPuzzle.validate(size, regions, board);
    });
  }

  Future<void> _saveGame() async {
    await GameStateStorage.instance.save(_savedStateId, {
      'level': _level,
      'score': _score,
      'size': _puzzle.size,
      'regions': _puzzle.regions,
      'solutionColumns': _puzzle.solutionColumns,
      'board': _board.map((s) => s.index).toList(),
    });
  }

  void _newPuzzleForLevel(int level) {
    final size = CatQueensPuzzle.sizeForLevel(level);
    _puzzle = CatQueensPuzzle.generate(_random, size);
    _board = List<CatCellState>.filled(size * size, CatCellState.empty);
    _markedAt.clear();
    _validation = const CatQueensValidation(conflicts: {}, solved: false);
  }

  void _resetBoard() {
    setState(() {
      _board = List<CatCellState>.filled(
        _puzzle.size * _puzzle.size,
        CatCellState.empty,
      );
      _markedAt.clear();
      _validation = const CatQueensValidation(conflicts: {}, solved: false);
    });
    _saveGame();
  }

  Future<void> _resetProgress() async {
    setState(() {
      _level = 1;
      _score = 0;
      _newPuzzleForLevel(_level);
    });
    await _saveGame();
  }

  /// Cycles a cell's state on tap:
  /// - empty -> marked (X)
  /// - marked -> cat, but only if tapped again within [_catWindow] of being
  ///   marked; otherwise (or once it's a cat) -> empty.
  /// - cat -> empty
  void _tapCell(int index) {
    if (_validation.solved) return;
    final current = _board[index];
    final CatCellState next;
    switch (current) {
      case CatCellState.empty:
        next = CatCellState.marked;
      case CatCellState.marked:
        final markedAt = _markedAt[index];
        final withinWindow = markedAt != null &&
            DateTime.now().difference(markedAt) <= _catWindow;
        next = withinWindow ? CatCellState.cat : CatCellState.empty;
      case CatCellState.cat:
        next = CatCellState.empty;
    }
    setState(() {
      _board[index] = next;
      if (next == CatCellState.marked) {
        _markedAt[index] = DateTime.now();
      } else {
        _markedAt.remove(index);
      }
      _validation = CatQueensPuzzle.validate(
        _puzzle.size,
        _puzzle.regions,
        _board,
      );
    });
    if (_validation.solved) {
      _onSolved();
    } else {
      if (_validation.conflicts.contains(index)) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
      _saveGame();
    }
  }

  /// Marks a single cell with an X while the player drags across the board
  /// without lifting their finger, so a whole row/column can be crossed out
  /// in one gesture. Cells that already hold a cat are left untouched so a
  /// stray drag can't wipe out a placed piece.
  void _dragMarkCell(int index) {
    if (_validation.solved) return;
    if (_board[index] != CatCellState.empty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _board[index] = CatCellState.marked;
      _markedAt[index] = DateTime.now();
      _validation = CatQueensPuzzle.validate(
        _puzzle.size,
        _puzzle.regions,
        _board,
      );
    });
    _saveGame();
  }

  void _giveHint() {
    if (_validation.solved) return;
    final size = _puzzle.size;
    final rows = List<int>.generate(size, (i) => i)..shuffle(_random);
    for (final row in rows) {
      final targetIndex = row * size + _puzzle.solutionColumns[row];
      if (_board[targetIndex] != CatCellState.cat) {
        HapticFeedback.lightImpact();
        setState(() {
          _board[targetIndex] = CatCellState.cat;
          _markedAt.remove(targetIndex);
          _validation = CatQueensPuzzle.validate(size, _puzzle.regions, _board);
        });
        if (_validation.solved) {
          _onSolved();
        } else {
          _saveGame();
        }
        return;
      }
    }
  }

  Future<void> _onSolved() async {
    HapticFeedback.mediumImpact();
    final gained = 50 + _puzzle.size * 30;
    setState(() => _score += gained);
    if (await ScoreService.instance.submitScore(_gameId, _score)) {
      if (mounted) setState(() => _bestScore = _score);
    }
    await _saveGame();
    if (mounted) _showSolvedDialog(gained);
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _newPuzzleForLevel(_level);
    });
    _saveGame();
  }

  void _showSolvedDialog(int gained) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('レベルクリア!'),
        content: Text('+$gained ポイント\nスコア: $_score'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextLevel();
            },
            child: const Text('次のレベルへ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsPlaced = _board.where((s) => s == CatCellState.cat).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ネコクイーンズ'),
        actions: [
          IconButton(
            onPressed: _giveHint,
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'ヒント',
          ),
          PopupMenuButton<_GameMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'メニュー',
            onSelected: (action) {
              switch (action) {
                case _GameMenuAction.resetBoard:
                  _resetBoard();
                case _GameMenuAction.resetProgress:
                  _resetProgress();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _GameMenuAction.resetBoard,
                child: Row(
                  children: [
                    Icon(Icons.replay),
                    SizedBox(width: 12),
                    Text('盤面をリセット'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _GameMenuAction.resetProgress,
                child: Row(
                  children: [
                    Icon(Icons.restart_alt),
                    SizedBox(width: 12),
                    Text('レベル1からやり直す'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBox(label: 'レベル', value: '$_level'),
                  _StatBox(label: 'スコア', value: '$_score'),
                  _StatBox(
                    label: 'ベスト',
                    value: _bestScore == null ? '--' : '$_bestScore',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '$catsPlaced / ${_puzzle.size}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _RuleChip('1色に1匹'),
                  _RuleChip('行と列に1匹ずつ'),
                  _RuleChip('ネコ同士は隣接不可'),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _CatQueensGrid(
                      puzzle: _puzzle,
                      board: _board,
                      conflicts: _validation.conflicts,
                      onTap: _tapCell,
                      onDragMark: _dragMarkCell,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

/// The board grid. A single tap on a cell cycles its state, while pressing
/// down and dragging across multiple cells without lifting the finger marks
/// every cell the drag passes over with an X -- handy for quickly crossing
/// out a row/column after placing a cat.
class _CatQueensGrid extends StatefulWidget {
  const _CatQueensGrid({
    required this.puzzle,
    required this.board,
    required this.conflicts,
    required this.onTap,
    required this.onDragMark,
  });

  final CatQueensPuzzle puzzle;
  final List<CatCellState> board;
  final Set<int> conflicts;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onDragMark;

  @override
  State<_CatQueensGrid> createState() => _CatQueensGridState();
}

class _CatQueensGridState extends State<_CatQueensGrid> {
  static const double _outerPadding = 4;

  final GlobalKey _boardKey = GlobalKey();
  int? _dragStartIndex;
  bool _isDragging = false;
  final Set<int> _dragVisited = {};

  int? _indexAt(Offset globalPosition) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPosition);
    final contentSize = box.size.width - _outerPadding * 2;
    final x = local.dx - _outerPadding;
    final y = local.dy - _outerPadding;
    if (x < 0 || y < 0 || x >= contentSize || y >= contentSize) return null;
    final cellSize = contentSize / widget.puzzle.size;
    final col = (x / cellSize).floor().clamp(0, widget.puzzle.size - 1);
    final row = (y / cellSize).floor().clamp(0, widget.puzzle.size - 1);
    return row * widget.puzzle.size + col;
  }

  void _resetDrag() {
    _dragStartIndex = null;
    _isDragging = false;
    _dragVisited.clear();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _dragStartIndex = _indexAt(event.position);
    _isDragging = false;
    _dragVisited.clear();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final start = _dragStartIndex;
    if (start == null) return;
    final index = _indexAt(event.position);
    if (index == null) return;

    if (!_isDragging) {
      if (index == start) return;
      _isDragging = true;
      _dragVisited.add(start);
      widget.onDragMark(start);
    }
    if (_dragVisited.add(index)) {
      widget.onDragMark(index);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_dragStartIndex != null && !_isDragging) {
      widget.onTap(_dragStartIndex!);
    }
    _resetDrag();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: (_) => _resetDrag(),
      child: Container(
        key: _boardKey,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(_outerPadding),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.puzzle.size,
          ),
          itemCount: widget.puzzle.size * widget.puzzle.size,
          itemBuilder: (context, index) {
            final region = widget.puzzle.regionAt(index);
            final color = _regionColors[region % _regionColors.length];
            final state = widget.board[index];
            final isConflict = widget.conflicts.contains(index);

            return Padding(
              padding: const EdgeInsets.all(1.5),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: isConflict
                      ? Border.all(color: colorScheme.error, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: switch (state) {
                  CatCellState.empty => null,
                  CatCellState.marked => Icon(
                      Icons.close_rounded,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  CatCellState.cat => const Text(
                      '🐱',
                      style: TextStyle(fontSize: 18),
                    ),
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
